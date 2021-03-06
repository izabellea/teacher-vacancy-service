module VacancyJobSpecificationValidations
  extend ActiveSupport::Concern
  include ApplicationHelper

  included do
    validates :job_title, presence: true
    validates :job_title, length: { minimum: 4, maximum: 100 }, if: :job_title?
    validate :job_title_has_no_tags?, if: :job_title?

    validates :job_roles, presence: true

    validates :working_patterns, presence: true

    validate :starts_on_in_future?, if: :starts_on?
    validate :ends_on_in_future?, if: :ends_on?
    validate :starts_on_before_ends_on?

    validate :starts_on_before_closing_date, if: :starts_on?
    validate :ends_on_before_closing_date, if: :ends_on?
  end

  def starts_on_before_ends_on?
    errors.add(:starts_on, starts_on_after_ends_on_error) if starts_on? && ends_on? && starts_on > ends_on
  end

  def starts_on_after_ends_on_error
    I18n.t('activerecord.errors.models.vacancy.attributes.starts_on.after_ends_on')
  end

  def starts_on_in_future?
    errors.add(:starts_on, starts_on_past_error) if starts_on.past?
  end

  def starts_on_past_error
    I18n.t('activerecord.errors.models.vacancy.attributes.starts_on.past')
  end

  def starts_on_before_closing_date
    errors.add(:starts_on, starts_on_must_be_before_closing_date_error) if expires_on? && starts_on <= expires_on
  end

  def ends_on_before_closing_date
    errors.add(:ends_on, ends_on_must_be_before_closing_date_error) if expires_on? && ends_on <= expires_on
  end

  def starts_on_must_be_before_closing_date_error
    I18n.t('activerecord.errors.models.vacancy.attributes.starts_on.before_expires_on')
  end

  def ends_on_must_be_before_closing_date_error
    I18n.t('activerecord.errors.models.vacancy.attributes.ends_on.before_expires_on')
  end

  def ends_on_in_future?
    errors.add(:ends_on, ends_on_past_error) if ends_on.past?
  end

  def ends_on_past_error
    I18n.t('activerecord.errors.models.vacancy.attributes.ends_on.past')
  end

  def job_title_has_no_tags?
    errors.add(
      :job_title, I18n.t('activemodel.errors.models.job_specification_form.attributes.job_title.invalid_characters')
    ) unless job_title == sanitize(job_title, tags: [])
  end
end
