require 'ostruct'

class TshirtsController < ApplicationController

  before_filter :login_required

  def buy_tshirt
    @credit_card = new_card
  end

  def transparent_redirect_complete
    result = SpreedlyCore.purchase(params[:token], "2")
    if result.code == 422
      @credit_card = new_card(result["transaction"]["payment_method"])
      @credit_card.errors = validation_errors_from(result.body)
      return render(:action => :buy_tshirt) 
    end

  end


  private
    def new_card(attributes = {})
      defaults = { "first_name" => nil, "last_name" => nil, "number" => nil, "verification_value" => nil }
      card = OpenStruct.new(defaults.merge(attributes))
      card.errors = ActiveModel::Errors.new(card) 
      card.class.extend ActiveModel::Translation
      card
    end

    def validation_errors_from(body)
      errors = ActiveModel::Errors.new(@credit_card)

      doc = Hpricot(body)
      doc.search("transaction>payment_method>errors>error").each do |each|
        errors.add(each.attributes['attribute'], I18n.t(each.attributes['key']))
      end

      errors
    end

end
