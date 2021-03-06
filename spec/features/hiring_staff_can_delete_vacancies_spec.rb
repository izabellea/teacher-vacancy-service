require 'rails_helper'
RSpec.feature 'School deleting vacancies' do
  let(:school) { create(:school) }
  let(:vacancy) { create(:vacancy, school: school) }
  let(:session_id) { SecureRandom.uuid }

  before(:each) do
    stub_hiring_staff_auth(urn: school.urn, session_id: session_id)
    stub_document_deletion_of_vacancy
  end

  scenario 'A school can delete a vacancy from a list' do
    vacancy2 = create(:vacancy, school: school)

    delete_vacancy(school, vacancy.id)

    expect(page).not_to have_content(vacancy.job_title)
    expect(page).to have_content(vacancy2.job_title)
    expect(page).to have_content('The job has been deleted')
  end

  scenario 'Deleting a vacancy triggers deletion of its supporting documents' do
    expect(vacancy).to receive(:delete_documents)

    delete_vacancy(school, vacancy.id)
  end

  scenario 'The last vacancy is deleted' do
    delete_vacancy(school, vacancy.id)

    expect(page).to have_content(I18n.t('schools.no_jobs.heading'))
  end

  scenario 'Audits the vacancy deletion' do
    delete_vacancy(school, vacancy.id)

    activity = vacancy.activities.last
    expect(activity.session_id).to eq(session_id)
    expect(activity.key).to eq('vacancy.delete')
  end

  scenario 'Notifies the Google index service' do
    expect_any_instance_of(HiringStaff::Vacancies::ApplicationController)
      .to receive(:remove_google_index).with(vacancy)

    delete_vacancy(school, vacancy.id)
  end

  private

  def delete_vacancy(school, vacancy_id)
    visit school_path(school)

    within("tr#school_vacancy_presenter_#{vacancy_id}") do
      click_on 'Delete'
    end
  end

  def stub_document_deletion_of_vacancy
    # Stub vacancy lookup so that the controller uses these tests' vacancy objects
    # to wrap the vacancy, instead of creating its own new vacancy object.
    # We need to use a `vacancy` object created in the test so that we can stub out the method
    # Vacancy#delete_documents, which otherwise will attempt HTTP connections.
    hiring_staff_vacancies_controller = HiringStaff::VacanciesController.new
    allow(HiringStaff::VacanciesController).to receive(:new).and_return(hiring_staff_vacancies_controller)
    allow(hiring_staff_vacancies_controller).to receive(:find_active_vacancy_by_id).and_return(vacancy)
    allow(vacancy).to receive(:delete_documents).and_return(nil)
  end
end
