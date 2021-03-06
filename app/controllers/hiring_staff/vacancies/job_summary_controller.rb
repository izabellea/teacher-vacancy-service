class HiringStaff::Vacancies::JobSummaryController < HiringStaff::Vacancies::ApplicationController
  before_action :redirect_unless_vacancy

  def show
    @job_summary_form = JobSummaryForm.new(@vacancy.attributes)
  end

  def update
    @job_summary_form = JobSummaryForm.new(job_summary_form_params)

    if @job_summary_form.valid?
      update_vacancy(job_summary_form_params, @vacancy)
      update_google_index(@vacancy) if @vacancy.listed?
      return redirect_to_next_step_if_save_and_continue(@vacancy.id)
    end

    render :show
  end

  private

  def job_summary_form_params
    params.require(:job_summary_form).permit(:job_summary, :about_school).merge(completed_step: current_step)
  end

  def next_step
    school_job_review_path(@vacancy.id)
  end
end
