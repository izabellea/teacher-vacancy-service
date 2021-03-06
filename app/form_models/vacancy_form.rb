class VacancyForm
  include ActiveModel::Model

  attr_accessor :vacancy

  delegate(*Vacancy.attribute_names.map { |attr| [attr, "#{attr}=", "#{attr}?"] }.flatten, to: :vacancy)
  delegate :save, to: :vacancy

  def initialize(params = {})
    @vacancy = Vacancy.new(
      params.except(:documents_attributes, :expiry_time_hh, :expiry_time_mm, :expiry_time_meridiem)
    )
  end

  def school
    @school ||= vacancy.school
  end

  def complete_and_valid?
    existing_errors = errors.dup
    is_valid = valid?
    existing_errors.messages.each do |field, error_array|
      error_array.each do |error|
        errors.add(field, error)
      end
    end
    errors.none? && is_valid
  end
end
