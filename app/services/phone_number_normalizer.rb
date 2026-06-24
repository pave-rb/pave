# frozen_string_literal: true

class PhoneNumberNormalizer
  BR_MOBILE_REGEX = /\A55\d{2}9?\d{8}\z/

  class << self
    def digits(value)
      value.to_s.gsub(/\D/, "").presence
    end

    def e164(value)
      normalized = digits(value)
      normalized.present? ? "+#{normalized}" : nil
    end

    def variations(value)
      normalized = digits(value)
      return [] if normalized.blank?
      return [ normalized ] unless normalized.match?(BR_MOBILE_REGEX)

      country_code = "55"
      area_code = normalized[2..3]
      rest = normalized[4..]

      if rest.length == 9 && rest.start_with?("9")
        [ normalized, "#{country_code}#{area_code}#{rest[1..]}" ]
      elsif rest.length == 8
        [ normalized, "#{country_code}#{area_code}9#{rest}" ]
      else
        [ normalized ]
      end
    end

    def e164_variations(value)
      variations(value).map { |candidate| "+#{candidate}" }
    end

    def preferred_outbound_e164(value)
      preferred = preferred_outbound_digits(value)
      preferred.present? ? "+#{preferred}" : nil
    end

    def preferred_outbound_digits(value)
      candidates = variations(value)
      return if candidates.blank?

      candidates.find { |candidate| brazilian_ninth_digit_mobile?(candidate) } || candidates.first
    end

    def equivalent?(left, right)
      left_digits = digits(left)
      right_digits = digits(right)
      return false if left_digits.blank? || right_digits.blank?
      return true if left_digits == right_digits

      variations(left_digits).include?(right_digits)
    end

    private

    def brazilian_ninth_digit_mobile?(value)
      normalized = digits(value)
      normalized.present? && normalized.match?(/\A55\d{2}9\d{8}\z/)
    end
  end
end
