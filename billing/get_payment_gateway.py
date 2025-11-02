from billing.payment_gateways.zarinpal import ZarinpalClient
from billing.payment_gateways.nowpayment import NowPaymentsClient

class GetPaymentGateway:
    @staticmethod
    def get_gateway(gateway):
        if gateway == 'zarinpal':
            return ZarinpalClient()
        elif gateway == 'nowpayments':
            return NowPaymentsClient()
        return None
