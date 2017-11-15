# frozen_string_literal: true

# <form action="https://docs.google.com/forms/d/e/1FAIpQLScP23rPNzExiipj0ahQ5M7zHi_TqmldaZPq2RaApl7ZlkZYuA/formResponse" method="POST" id="ss-form" target="_self" autocomplete="on" onsubmit="">
#   <ol role="list" class="ss-question-list" style="padding-left: 0;">
#     <div class="ss-form-question errorbox-good" role="listitem">
#       <div dir="auto" class="ss-item  ss-paragraph-text">
#         <div class="ss-form-entry">
#           <label class="ss-q-item-label" for="entry_286043971"><div class="ss-q-title">Feedback</div><div class="ss-q-help ss-secondary-text" dir="auto"></div></label>
#           <textarea name="entry.286043971" rows="8" cols="0" class="ss-q-long" id="entry_286043971" dir="auto" aria-label="Feedback  "></textarea>
#           <div class="error-message" id="324742605_errorMessage"></div>
#           <div class="required-message">This is a required question</div>
#         </div>
#       </div>
#     </div>
#
#     <input type="hidden" name="draftResponse" value="[null,null,&quot;-5122201194019342916&quot;]">
#     <input type="hidden" name="pageHistory" value="0">
#     <input type="hidden" name="fbzx" value="-5122201194019342916">
#     <div class="ss-send-email-receipt" style="margin-bottom: 4px;" dir="ltr"><label for="emailReceipt" style="display:inline;"></label></div>
#
#     <div class="ss-item ss-navigate">
#       <table id="navigation-table">
#         <tbody>
#           <tr>
#             <td class="ss-form-entry goog-inline-block" id="navigation-buttons" dir="ltr">
#               <input type="submit" name="submit" value="Submit" id="ss-submit" class="jfk-button jfk-button-action ">
#               <div class="ss-password-warning ss-secondary-text">Never submit passwords through Google Forms.</div>
#             </td>
#           </tr>
#         </tbody>
#       </table>
#     </div>
#   </ol>
# </form>

class FeedbacksController < ApplicationController
  def create
    feedback = feedback_params['feedback']
    HTTParty.post('https://docs.google.com/forms/d/e/1FAIpQLScP23rPNzExiipj0ahQ5M7zHi_TqmldaZPq2RaApl7ZlkZYuA/formResponse', body: { 'entry.286043971': feedback })
  end

  private

    def feedback_params
      params.require(:feedback).permit(:feedback)
    end
end
