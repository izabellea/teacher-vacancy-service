module VacancyCopyValidations
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    validates :job_title, presence: true
    validates :job_title, length: { minimum: 4, maximum: 100 }, if: :job_title?
    validate :job_title_has_no_tags?, if: :job_title?

    validates :job_roles, presence: true

    validates :about_school, presence: true
  end

  def job_title_has_no_tags?
    errors.add(
      :job_title, I18n.t('activemodel.errors.models.job_specification_form.attributes.job_title.invalid_characters')
    ) unless job_title == sanitize(job_title, tags: [])
  end
end
