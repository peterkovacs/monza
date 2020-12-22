require 'time'
require 'active_support/core_ext/time'

module Monza
  class TransactionReceipt
    using BoolTypecasting

    # Receipt Fields Documentation
    # https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1

    # The number of consumable products purchased. This value corresponds to
    # the quantity property of the SKPayment object stored in the transaction's
    # payment property. The value is usually “1” unless modified with a mutable
    # payment. The maximum value is 10.
    attr_reader :quantity

    # The unique identifier of the product purchased. You provide this value
    # when creating the product in App Store Connect, and it corresponds to the
    # productIdentifier property of the SKPayment object stored in the
    # transaction's payment property.
    attr_reader :product_id

    # A unique identifier for a transaction such as a purchase, restore, or renewal.
    attr_reader :transaction_id
    # The identifier of the subscription offer redeemed by the user.
    attr_reader :promotional_offer_id
    # The transaction identifier of the original purchase.
    attr_reader :original_transaction_id

    # For consumable, non-consumable, and non-renewing subscription products,
    # the time the App Store charged the user's account for a purchased or
    # restored product. For auto-renewable subscriptions, the time the App
    # Store charged the user’s account for a subscription purchase or renewal
    # after a lapse. Use this time format for processing dates.
    attr_reader :purchase_date
    attr_reader :purchase_date_ms
    attr_reader :purchase_date_pst

    # The time of the original app purchase. Use this time format for
    # processing dates. For an auto-renewable subscription, this value
    # indicates the date of the subscription's initial purchase. The original
    # purchase date applies to all product types and remains the same in all
    # transactions for the same product ID. This value corresponds to the
    # original transaction’s transactionDate property in StoreKit.
    attr_reader :original_purchase_date
    attr_reader :original_purchase_date_ms
    attr_reader :original_purchase_date_pst

    # A unique identifier for purchase events across devices, including
    # subscription-renewal events. This value is the primary key for
    # identifying subscription purchases.
    attr_reader :web_order_line_item_id

    # The time a subscription expires or when it will renew.
    attr_reader :expires_date
    attr_reader :expires_date_ms
    attr_reader :expires_date_pst

    # The time Apple customer support canceled a transaction, or the time an
    # auto-renewable subscription plan was upgraded. This field is only present
    # for refunded transactions. Use this time format for processing dates.
    attr_reader :cancellation_date
    attr_reader :cancellation_date_ms
    attr_reader :cancellation_date_pst
    # The reason for a refunded transaction. When a customer cancels a
    # transaction, the App Store gives them a refund and provides a value for
    # this key. A value of “1” indicates that the customer canceled their
    # transaction due to an actual or perceived issue within your app. A value
    # of “0” indicates that the transaction was canceled for another reason;
    # for example, if the customer made the purchase accidentally.
    attr_reader :cancellation_reason

    # An indicator of whether a subscription is in the free trial period.
    attr_reader :is_trial_period
    # An indicator of whether an auto-renewable subscription is in the introductory price period.
    attr_reader :is_in_intro_offer_period
    # An indicator that a subscription has been canceled due to an upgrade.
    # This field is only present for upgrade transactions.
    attr_reader :is_upgraded

    # The identifier of the subscription group to which the subscription
    # belongs. The value for this field is identical to the
    # subscriptionGroupIdentifier property in SKProduct.
    attr_reader :subscription_group_identifier
    attr_reader :original_attributes

    def initialize(attributes)
      @original_attributes = attributes
      @quantity = attributes['quantity'].to_i
      @product_id = attributes['product_id']
      @transaction_id = attributes['transaction_id']
      @original_transaction_id = attributes['original_transaction_id']
      @promotional_offer_id = attributes['promotional_offer_id']

      @purchase_date = DateTime.parse(attributes['purchase_date']) if attributes['purchase_date']
      @purchase_date_ms = Time.zone.at(attributes['purchase_date_ms'].to_i / 1000)
      @purchase_date_pst = date_for_pacific_time(attributes['purchase_date_pst']) if attributes['purchase_date_pst']
      @original_purchase_date = DateTime.parse(attributes['original_purchase_date']) if attributes['original_purchase_date']
      @original_purchase_date_ms = Time.zone.at(attributes['original_purchase_date_ms'].to_i / 1000)
      @original_purchase_date_pst = date_for_pacific_time(attributes['original_purchase_date_pst']) if attributes['original_purchase_date_pst']
      @web_order_line_item_id = attributes['web_order_line_item_id']

      if attributes['expires_date']
        begin
          # Attempt to parse as RFC 3339 timestamp (new-style receipt)
          @expires_date = DateTime.parse(attributes['expires_date'])
        rescue
          # Attempt to parse as integer ms epoch (old-style receipt)
          @expires_date = Time.at(attributes['expires_date'].to_i / 1000).to_datetime
        end
      end
      if attributes['expires_date_ms']
        @expires_date_ms = Time.zone.at(attributes['expires_date_ms'].to_i / 1000)
      elsif attributes['expires_date']
        @expires_date_ms = Time.zone.at(attributes['expires_date'].to_i / 1000)
      end
      if attributes['expires_date_pst']
        @expires_date_pst = date_for_pacific_time(attributes['expires_date_pst'])
      end
      if attributes['is_trial_period']
        @is_trial_period = attributes['is_trial_period'].to_bool
      end
      if attributes['is_in_intro_offer_period']
        @is_in_intro_offer_period = attributes['is_in_intro_offer_period'].to_bool
      end
      if attributes['is_upgraded']
        @is_upgraded = attributes['is_upgraded'].to_bool
      end
      if attributes['subscription_group_identifier']
        @subscription_group_identifier = attributes['subscription_group_identifier']
      end

      if attributes['cancellation_date']
        @cancellation_date = DateTime.parse(attributes['cancellation_date'])
      end
      if attributes['cancellation_date_ms']
        @cancellation_date_ms = Time.zone.at(attributes['cancellation_date_ms'].to_i / 1000)
      end
      if attributes['cancellation_date_pst']
        @cancellation_date_pst = date_for_pacific_time(attributes['cancellation_date_pst'])
      end
      @cancellation_reason = attributes['cancellation_reason']

    end # end initialize

    def date_for_pacific_time pt
      # The field is labelled "PST" by apple, but the "America/Los_Angelus" time zone is actually Pacific Time, 
      # which is different, because it observes DST.
      ActiveSupport::TimeZone["Pacific Time (US & Canada)"].parse(pt).to_datetime
    end

    #
    # Depcrecating - don't use these
    # These will only work if the user never cancels and then resubscribes
    # The original_transaction_id does not reset after the user resubscribes
    #
    # def is_renewal?
    #   !is_first_transaction?
    # end
    #
    # def is_first_transaction?
    #   @original_transaction_id == @transaction_id
    # end
  end # end class
end # end module

#
# Sample JSON Object
#
#       {
#         "quantity": "1",
#         "product_id": "product_id",
#         "transaction_id": "1000000218147651",
#         "original_transaction_id": "1000000218147500",
#         "purchase_date": "2016-06-17 01:32:28 Etc/GMT",
#         "purchase_date_ms": "1466127148000",
#         "purchase_date_pst": "2016-06-16 18:32:28 America/Los_Angeles",
#         "original_purchase_date": "2016-06-17 01:30:33 Etc/GMT",
#         "original_purchase_date_ms": "1466127033000",
#         "original_purchase_date_pst": "2016-06-16 18:30:33 America/Los_Angeles",
#         "expires_date": "2016-06-17 01:37:28 Etc/GMT",
#         "expires_date_ms": "1466127448000",
#         "expires_date_pst": "2016-06-16 18:37:28 America/Los_Angeles",
#         "web_order_line_item_id": "1000000032727764",
#         "is_trial_period": "false"
#       }
