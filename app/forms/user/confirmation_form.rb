# frozen_string_literal: true

class User::ConfirmationForm < BaseForm

  include GobiertoCommon::CustomUserFieldsHelper

  attr_accessor(
    :confirmation_token,
    :name,
    :password_enabled,
    :password,
    :password_confirmation,
    :date_of_birth_year,
    :date_of_birth_month,
    :date_of_birth_day,
    :date_of_birth,
    :gender,
    :creation_ip,
    :site,
    :document_number
  )
  attr_reader :user

  validates :name, :date_of_birth, :gender, :user, presence: true
  validates :password, presence: true, confirmation: true, if: :password_enabled
  validate :user_verification

  def initialize(options = {})
    options = options.to_h.with_indifferent_access
    ordered_options = options.slice(:site, :confirmation_token).merge!(options)

    super(ordered_options)
  end

  def require_user_verification?
    user.present? && user.referrer_entity == "GobiertoBudgetConsultations::Consultation"
  end

  def save
    return false unless valid?

    confirm_user if save_user
  end

  def password_enabled
    @password_enabled = true if @password_enabled.nil?
    @password_enabled
  end

  def user
    @user ||= User.find_by(confirmation_token: confirmation_token, site: site)
  end

  def name
    @name ||= user.name if user
  end

  def email
    @email ||= user.email
  end

  def gender
    @gender ||= user.gender if user
  end

  def date_of_birth_year
    @date_of_birth_year ||= user.date_of_birth.try(:year) if user
  end

  def date_of_birth_month
    @date_of_birth_month ||= user.date_of_birth.try(:month) if user
  end

  def date_of_birth_day
    @date_of_birth_day ||= user.date_of_birth.try(:day) if user
  end

  def date_of_birth
    @date_of_birth ||= if date_of_birth_year && date_of_birth_month && date_of_birth_day
      Date.new(
        date_of_birth_year.to_i,
        date_of_birth_month.to_i,
        date_of_birth_day.to_i
      )
    end
  rescue ArgumentError
    nil
  end

  def census_verification
    @census_verification ||= User::Verification::CensusVerification.new
  end

  private

  def save_user
    @user = user.tap do |user_attributes|
      user_attributes.name = name
      user_attributes.password = password if password_enabled
      user_attributes.date_of_birth = date_of_birth
      user_attributes.gender = gender
      user_attributes.custom_records = custom_records
    end

    if !@user.valid?
      promote_errors(@user.errors)
      return false
    end

    if require_user_verification?
      @census_verification = build_census_verification

      if !@census_verification.valid?
        promote_errors(@census_verification.errors)
        return false
      end

      if !@census_verification.will_verify?
        errors[:base] << "#{I18n.t('activemodel.models.user/census_verification_form')} #{I18n.t('errors.messages.invalid')}"
        return false
      end

      ActiveRecord::Base.transaction do
        @user.save
        @census_verification.save
        @census_verification.verify!
      end

      return @user
    else
      @user.save
      return @user
    end
  end

  def confirm_user
    user.confirm!
    deliver_welcome_email
    enable_notifications
  end

  def user_verification
    if require_user_verification? && document_number.blank?
      errors.add(:document_number, I18n.t('errors.messages.blank'))
    end
  end

  def build_census_verification
    census_verification.tap do |census_verification_attributes|
      census_verification_attributes.site = site
      census_verification_attributes.user = @user
      census_verification_attributes.creation_ip = creation_ip
      census_verification_attributes.document_number = document_number
      census_verification_attributes.date_of_birth = @user.date_of_birth
    end
  end

  protected

  def deliver_welcome_email
    if user
      User::UserMailer.welcome(user, user.site).deliver_later
    end
  end

  def enable_notifications
    user.immediate_notifications!
  end
end
