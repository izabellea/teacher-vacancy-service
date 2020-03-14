require 'breasal'
require 'google/cloud/bigquery'

class School < ApplicationRecord
  include Auditor::Model
  include Google::Cloud

  BIGQUERY_DATASET = ENV.fetch('BIG_QUERY_DATASET')
  BIGQUERY_TABLE_PREFIX = ActiveRecord::Migrator.current_version

  belongs_to :school_type, optional: false
  belongs_to :detailed_school_type, optional: true
  belongs_to :region

  has_many :vacancies

  validates :urn, uniqueness: true

  delegate :name, to: :region, prefix: true

  enum phase: {
    not_applicable: 0,
    nursery: 1,
    primary: 2,
    middle_deemed_primary: 3,
    secondary: 4,
    middle_deemed_secondary: 5,
    sixteen_plus: 6,
    all_through: 7,
  }

  alias_attribute :data, :gias_data

  def easting=(easting)
    self[:easting] = easting
    set_geolocation_from_easting_and_northing
  end

  def northing=(northing)
    self[:northing] = northing
    set_geolocation_from_easting_and_northing
  end

  def has_religious_character?
    return false if !self.respond_to?(:gias_data) || self.gias_data == nil
    ['None', 'Does not apply', nil].exclude?(self.gias_data['religious_character'])
  end

  def bigquery_export(bigquery: Bigquery.new)
    dataset = bigquery.dataset(BIGQUERY_DATASET)
    table_name = [BIGQUERY_TABLE_PREFIX, self.class.name.to_s.downcase.pluralize].join('_')
    table = dataset.table(table_name)
    table = dataset.create_table(table_name) do |schema|
      bigquery_schema.each do |column_name, column_type|
        schema.send(column_type, column_name)
      end
    end if table.nil?

    table.insert(bigquery_data)
  end

  def bigquery_data
    @bigquery_data = {}
    drop_these_attributes = %w[
    benefits
    description
    education
    experience
    geolocation
    gias_data
    job_description
    qualifications
    supporting_documents
    ].freeze

    self.class.columns.map do |c|
      next if drop_these_attributes.include?(c.name)
      data = self.send(c.name)
      data = data.to_s(:db) if (c.type == :datetime || c.type == :date)
      data = data.to_a if c.name == 'geolocation'
      @bigquery_data[c.name] = data
    end

    if self.class.column_names.include?('geolocation')
      @bigquery_data['geolocation_x'] = geolocation.x
      @bigquery_data['geolocation_y'] = geolocation.y
    end

    no_gias_data = gias_data.nil?
    gias = gias_data || self.class.where.not(gias_data: nil).first.gias_data
    gias.map do |key, value|
      data = no_gias_data ? nil : value
      data = nil if data.empty?
      data = Date.parse(data).to_s(:db) if data.is_a?(String) && data.match?(/^\d{2}\-\d{2}\-\d{4}/)
      data = data.to_i if data.is_a?(String) && data.match?(/^\d+$/)
      @bigquery_data["data_#{key.chomp(')').gsub(/\W+/, '_')}"] = data
    end
    @bigquery_data
  end

  def bigquery_schema
    @bigquery_schema = {}
    convert_these_attributes = {
      'phase' => :string
    }

    convert_these_types = {
      point: :float,
      text: :string,
      uuid: :string,
    }

    drop_these_attributes = %w[
      benefits
      description
      education
      experience
      geolocation
      gias_data
      job_description
      qualifications
      supporting_documents
    ].freeze

    self.class.columns.map do |c|
      next if drop_these_attributes.include?(c.name)
      @bigquery_schema[c.name] = convert_these_attributes[c.name] || convert_these_types[c.type] || c.type
    end.compact

    if self.class.column_names.include?('geolocation')
      @bigquery_schema['geolocation_x'] = :float
      @bigquery_schema['geolocation_y'] = :float
    end

    gias = gias_data || self.class.where.not(gias_data: nil).first.gias_data

    gias.map do |key, value|
      data_type = :string
      data_type = :date if key.match(/date/i)
      data_type = :integer if value.match(/^\d+$/)
      @bigquery_schema["data_#{key.chomp(')').gsub(/\W+/, '_')}"] = data_type
    end

    @bigquery_schema
  end

  private

  def set_geolocation_from_easting_and_northing
    if easting && northing
      wgs84 = Breasal::EastingNorthing.new(
        easting: easting.to_i,
        northing: northing.to_i,
        type: :gb
      ).to_wgs84

      geolocation = [wgs84[:latitude], wgs84[:longitude]]
    end

    self.geolocation = geolocation
  end
end
