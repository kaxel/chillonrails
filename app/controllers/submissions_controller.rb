class SubmissionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create, :success ]

  def new
    @page_title = "submit"
    @submission = Submission.new
    @submission.submission_songs.build
  end

  def create
    @submission = Submission.new(submission_params)

    if @submission.save
      @submission.recalculate_amount!
      checkout = create_checkout_session(@submission)
      @submission.update!(stripe_session_id: checkout.id)
      redirect_to checkout.url, allow_other_host: true, status: :see_other
    else
      @page_title = "submit"
      render :new, status: :unprocessable_entity
    end
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe checkout failed for submission #{@submission&.id}: #{e.message}")
    @submission&.destroy
    redirect_to submit_path, alert: t("submissions.payment_start_failed")
  end

  def success
    @submission = Submission.find_by!(token: params[:token])
    @page_title = "submission received"
  end

  private

  def submission_params
    params.expect(
      submission: [ :contact_name, :email, :artist_name,
                    submission_songs_attributes: [ [ :title, :audio ] ] ]
    )
  end

  def create_checkout_session(submission)
    Stripe::Checkout::Session.create(
      mode: "payment",
      customer_email: submission.email,
      line_items: [ {
        quantity: submission.song_count,
        price_data: {
          currency: "usd",
          unit_amount: Submission::PRICE_PER_SONG_CENTS,
          product_data: { name: "CHILLFILTR® song submission (listening fee)" }
        }
      } ],
      metadata: { submission_id: submission.id },
      success_url: submission_success_url(submission.token) + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: submit_url
    )
  end
end
