# frozen_string_literal: true

# == Schema Information
#
# Table name: items
#
#  id                  :bigint(8)        not null, primary key
#  discount_percentage :integer          default(0)
#  has_discount        :boolean          default(FALSE)
#  name                :string           default("Item"), not null
#  original_price      :float            not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Item < ApplicationRecord
  # TODO: what value for dependent here? rubocop insists on declaring that option
  has_many :categorizings,
           dependent: :destroy

  has_many :categories,
           through: :categorizings,
           dependent: :destroy

  validates :original_price,
            presence: true,
            numericality: { greater_than: 0 }
  validates :has_discount,
            inclusion: {    in: [true, false],
                            message: "is not a boolean value" }
  validates :discount_percentage,
            presence: true,
            numericality: { only_integer: true,
                            less_than: 100 }

  def price
    if has_discount
      (original_price - original_price * discount_percentage.to_f / 100).round(2)
    else
      original_price
    end
  end

  def self.average_price
    # use DB function here -> @zaratan
    # all.map(:price).sum / count
    sum_discounted_items = 0

    sum_non_discounted_items = where(has_discount: false).sum(:original_price)

    discounted_items = where(has_discount: true).pluck(:original_price, :discount_percentage)
    discounted_items.each { |i| sum_discounted_items += apply_discount(i[0], i[1]) }

    (sum_non_discounted_items + sum_discounted_items) / count
  end

  def self.apply_discount(price, percentage)
    (price - price * percentage / 100).round(2)
  end
end
