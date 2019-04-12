# frozen_string_literal: true

require 'typhoeus'
require 'json'
require 'bagit'
require 'time'
require 'active_support'
require 'active_support/time'
ENV["TZ"] = "US/Eastern"

desc "rake export monographs bags for a given press id"
namespace :aptrust do
  task :bag_updated_monographs => :environment do |_t, args|
    # Usage: Needs a valid press id as a parameter
    # $ ./bin/rails "aptrust:bag_new_and_updated_monographs"

    BAG_STATUSES = { 'not_bagged' => 0, 'bagged' => 1, 'bagging_failed' => 3 } .freeze
    S3_STATUSES = { 'not_uploaded' => 0, 'uploaded' => 1, 'upload_failed' => 3 }.freeze
    APT_STATUSES = { 'not_checked' => 0, 'confirmed' => 1, 'pending' => 3, 'failed' => 4, 'not_found' => 5, 'bad_aptrust_response_code' => 6 }.freeze

    # SAVING FOR POSSIBLE LATER USE
    # upload_docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:#{args.press_id} AND +visibility_ssi:'open'",
    #                                          fq: '-suppressed_bsi:true',
    #                                          fl: ['id', 'press_tesim', 'author_tesim', 'description_tesim', 'identifier_tesim', 'title_tesim', 'date_modified_tesim', 'date_uploaded_dtsi'],
    #                                          sort: 'date_uploaded_dtsi asc',
    #                                          rows: 100000)

    # children = @press.children.pluck(:subdomain)
    # presses = children.push(@press.subdomain).uniq

    # subsequent runs:
    # - use Solr calls to pull all *published* Monographs with their mod dates and child ids
    def monographs_solr_all_published
      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph",
       rows: 100000)
      published_docs = docs.select { |doc| doc["suppressed_bsi"] == false && doc["visibility_ssi"] == "open" }

      # puts "back from gathering published_docs with document count #{published_docs.count}" unless published_docs.nil?
      published_docs
    end

    def update_record(record)
      solr_monographs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph",
                                      fq: "id:#{record.id}",
                                      fl: ['id',
                                          'press_tesim',
                                          'creator_tesim',
                                          'identifier_tesim',
                                          'title_tesim',
                                          'date_modified_dtsi',
                                          'has_model_ssim'])
      # puts "In update_record, solr_monographs count is: #{solr_monographs.count}"
      data = solr_monographs.first

      if data['press_tesim'].blank?
        apt_log(record.id.to_s, 'rake - update_record', 'building record', 'error', "In update_record press_tesim was blank, returning nil")
        return nil
      else
        press = data['press_tesim'].first[0..49]
      end

      if data['title_tesim'].blank?
        apt_log(record.id.to_s, 'rake - update_record', 'building record', 'error', "In update_record title_tesim was blank, returning nil")
        return nil
      else
        title = data['title_tesim'].first[0..249]
      end

      if data['has_model_ssim'].blank?
        apt_log(record.id.to_s, 'rake - update_record', 'building record', 'error', "In update_record has_model_ssim was blank, returning nil")
        return nil
      else
        model = data['has_model_ssim'].first[0..49]
      end

      # These we just need to adjust, but not return nil
      if data['creator_tesim'].blank?
        apt_log(record.id.to_s, 'rake - update_record', 'building record', 'warn', "In update_record creator_tesim was blank")
        creator = ''
      else
        creator = data['creator_tesim'].first[0..49]
      end

      if data['date_modified_dtsi'].blank?
        apt_log(record.id.to_s, 'rake - update_record', 'building record', 'warn', "In update_record date_modified_dtsi was blank")
        date_mod = nil
      else
        date_mod = data['date_modified_dtsi']
      end

      begin
        record.update!(
                        # noid:  up_doc[:id], # this is already in record
                        press: press,
                        author: creator,
                        title: title,
                        model: model,
                        bag_status: BAG_STATUSES['not_bagged'],
                        s3_status: S3_STATUSES['not_uploaded'],
                        apt_status: APT_STATUSES['not_checked'],
                        date_monograph_modified: date_mod,
                        date_bagged: nil,
                        date_uploaded: nil,
                        date_confirmed: nil
                      )
      rescue ActiveRecord::RecordInvalid => e
        record = nil
      end
      record
    end

    def check_mono_mod_date(record, pdoc)
      record_bagged_time = DateTime.parse(record.date_bagged.to_s).utc
      pub_pdoc_time = DateTime.parse(pdoc['date_modified_dtsi'].to_s).utc
      need_to_recreate = (pub_pdoc_time > record_bagged_time)
      need_to_recreate
    end

    def check_mono_fileset_mod_dates(record, pdoc)
      # Try to get the filesets for this published monograph; if there are none return false
      pdoc_fsets = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND +monograph_id_ssim:#{pdoc[:id]}", rows: 100_000)
      return false if pdoc_fsets.blank?

      # Get date_bagged from database
      return false if record.date_bagged.blank?

      record_bagged_time = DateTime.parse(record.date_bagged.to_s).utc

      need_to_recreate = false

      # Loop through filesets to see if any have a newer date than the db date_bagged
      pdoc_fsets.each do |fset|
        # if we found a newer date stop checking
        unless need_to_recreate
          fset_time = DateTime.parse(fset['date_modified_dtsi']).utc
          need_to_recreate = (fset_time > record_bagged_time)
        end
      end
      need_to_recreate
    end

    def update_db_aptrust_status(record)
      return nil if record.nil?

      filename = Rails.root.join('config', 'aptrust.yml')
      yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
      @aptrust = yaml || nil
      abort "Not getting authentication secrets via @aptrust yml" if @aptrust.nil?

      heads = {}
      heads["Content-Type"] = "application/json"
      heads["Accept"] = "application/json"
      heads["X-Pharos-API-User"] = @aptrust['AptrustApiUser']
      heads["X-Pharos-API-Key"] = @aptrust['AptrustApiKey']

      base_apt_url = @aptrust['AptrustApiUrl']
      bag_name = "fulcrum.org.#{record['press']}-#{record['id']}.tar"

      updated_after = Time.parse(record['date_uploaded'].to_s) - (60 * 60 * 24)
      updated_after = updated_after.iso8601

      this_url = base_apt_url + "items/?per_page=200&action=ingest&name=#{bag_name}&updated_after=#{updated_after}"
      # puts "this_url: #{this_url}"

      response = Typhoeus.get(this_url, headers: heads)

      # unless response.nil?
      #   puts "response.body: #{response.body}"
      #   puts "response.code: #{response.code}"
      #   puts "response.total_time: #{response.total_time}"
      #   # puts "response.headers: #{response.headers}"
      # end

      apt_key = ''

      if response.code != 200
        apt_key = 'bad_aptrust_response_code'
        apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'warn', "In update_db_aptrust_status we got non-200 response.code (#{response.code}) from aptrust")
        # removed 'response.body['count'].to_i.zero? ||' from the following line
      elsif response.body['results'].blank?
        apt_key = 'not_found'
        apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'warn', "In update_db_aptrust_status we got empty response results from aptrust")
      else
        # Keep parsing and update record
        parsed = JSON.parse(response.response_body)

        # Now we know we have results to work with.
        # We might get back more than one matching aptrust record
        # the following handles that possibility by find the most current one
        saved_results = {}

        parsed["results"].each do |res|
          current_results = res

          # See if we've already stored a subhash for this noid
          if saved_results.empty?
            saved_results = current_results
          else
            saved_datetime = DateTime.parse(saved_results['bag_date'].to_s).utc
            current_datetime = DateTime.parse(current_results['bag_date'].to_s).utc

            # Replace saved_results with current_results if current bag_date is newer
            saved_results = current_results if current_datetime > saved_datetime
          end
        end

        apt_stage = ''
        case saved_results['stage']
        when 'Store', 'Record', 'Cleanup', 'Resolve'
          # After validate stage
          apt_stage = 'ingest_complete'
        when 'Requested', 'Receive', 'Fetch', 'Unpack', 'Validate'
          # Before or during validate stage
          apt_stage = 'ingest_could_fail'
        else
          apt_stage = 'ingest_could_fail'
        end

        case saved_results['status']
        when 'Success'
          apt_key = 'confirmed' if apt_stage == 'ingest_complete'
          apt_key = 'pending' if apt_stage == 'ingest_could_fail'
          apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'okay', "In update_db_aptrust_status, #{apt_key} deposit for record: #{record['id']} bag: #{bag_name}")
        when 'Started', 'Pending'
          apt_key = 'pending'
          apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'okay', "In update_db_aptrust_status, pending deposit for record: #{record['id']} bag: #{bag_name}")
        when 'Failed', 'Cancelled'
          apt_key = 'failed'
          apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'okay', "In update_db_aptrust_status, failed deposit for record: #{record['id']} bag: #{bag_name}")
        else
          apt_key = 'failed'
          apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'okay', "In update_db_aptrust_status, (else) failed deposit for record: #{record['id']} bag: #{bag_name}")
        end
      end

      # Update the db, using the apt_key
      puts "Updating the apt_status of DB record for noid #{record.id} to #{apt_key}"
      apt_log(record.id.to_s, 'rake - update_db_aptrust_status', 'DB update', 'okay', "Updating the apt_status of DB record for noid #{record.id} to #{apt_key}")

      begin
        record.update!(
                        apt_status: APT_STATUSES[apt_key]
                      )
      rescue ActiveRecord::RecordInvalid => e
        record = nil
      end
      record
    end

    def validate_or_kill_record(record)
      # Ugh, if record got saved without a press it will cause problems
      # so kill it.
      rtn_val = record
      chk_list = ['noid', 'press', 'model', 'bag_status', 's3_status', 'apt_status']
      chk_list.each do |item|
        if record[item].blank?
          puts "In validate_or_kill_record, record.#{item} was blank for noid #{record.id}"
          record.destroy
          rtn_val = nil
          next
        end
      end
      rtn_val
    end

    def build_record_and_bag(noid)
      # puts "In build_record_and_bag working with noid #{noid}"
      record = AptrustUpload.find_by(noid: noid)
      if record.nil?
        # puts "In build_record_and_bag, could not find a record for noid #{noid}, will try to create one"
        record = AptrustUpload.create(noid:  noid)
        if record.nil?
          puts "In build_record_and_bag, create_record failed for noid: #{noid}"
          return nil
        else
          # Good so far, let's update the record with solr data
          record = update_record(record)
          if record.nil?
           puts "In build_record_and_bag, could not update_record a record for noid #{noid}"
           return nil
         end
        end
      end

      # Found or created record but is it good?
      record = validate_or_kill_record(record)
      if record.nil?
        puts "In build_record_and_bag, validate_or_kill_record failed for noid: #{noid}"
        return nil
      else
        # puts "In build_record_and_bag, about to create a bag for noid #{noid} and record #{record}"
        exporter = Export::Exporter.new(record.id, :monograph)
        exporter.export_bag
      end
      record
    end

    def apt_log(noid, where, stage, status, action)
      begin
        AptrustLog.create(noid: noid,
                        where: where,
                        stage: stage,
                        status: status,
                        action: action)
      rescue AptrustUpload::RecordInvalid => e
        puts "DB error #{e} when trying to log to AptrustLog with noid: #{noid} where: #{where} stage: #{stage} status: #{status} action: #{action}"
      end
    end

    puts "Starting task bag_updated_monographs."

    apt_log('na', 'bag_updated_monographs', 'before getting solr_monographs', 'okay', "Starting task bag_updated_monographs.")

    solr_monographs = monographs_solr_all_published

    if solr_monographs.nil?
      apt_log('na', 'bag_updated_monographs', 'after getting solr_monographs', 'error', "WARNING aborted because solr_monographs is NIL!")
      abort "WARNING in aptrust:bag_updated_monographs task solr_monographs is NIL!" 
    end

    # Check solr docs for ones that represent new or update monographs
    # pdoc means published monograph
    begin
      solr_monographs.each do |pdoc|
        noid = pdoc[:id].to_s
        puts "Checking on published monograph with noid: #{noid}"
        apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'begining checks', 'okay', "Checking on pdoc with noid: #{noid}")
        record = AptrustUpload.find_by(noid: noid)
        if record.nil?
          # We didn't find a record, so we need a record and a bag
          apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'checking record exists', 'okay', "No DB record for noid, so we need to create a record and a bag")
          build_record_and_bag(noid)
        elsif record.bag_status == BAG_STATUSES['not_bagged']
          # There is a db record but this noid hasn't been bagged yet
          apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'checking record bag status', 'okay', "DB record bagged status is 'not bagged' for noid, so update record and recreate bag")
          build_record_and_bag(noid)
        elsif check_mono_mod_date(record, pdoc)
          # if doc modified date is more recent that db bagged date
          apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'check_mono_mod_date', 'okay', "pdoc mod date is more recent than record mod date, so update record and recreate bag")
          build_record_and_bag(noid)
        elsif check_mono_fileset_mod_dates(record, pdoc)
          # If any of the docs filesets modified date is more recent that db bagged date
          apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'check_mono_fileset_mod_dates', 'okay', "a fileset mod date is more recent than record mod date, so update record and recreate bag")
          build_record_and_bag(noid)
        else
          # Otherwise check deposit for this pdoc in aptrust and update DB
          apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'update_db_aptrust_status', 'okay', "about try to confirming deposit status")
          check = update_db_aptrust_status(record)
          apt_log(noid, 'bag_updated_monographs - solr_monographs.each', 'after update_db_aptrust_status', 'error', "there was a problem checking deposit status") if check.nil?
        end
      end
    rescue StandardError => e
      apt_log('na', 'bag_updated_monographs - solr_monographs.each', 'checking published monographs', 'error', "Rescue StandardError failed with error: #{e}")
      abort "Rescue StandardError failed with error: #{e}"
    end

    puts "Task bag_updated_monographs complete."
  end
end
