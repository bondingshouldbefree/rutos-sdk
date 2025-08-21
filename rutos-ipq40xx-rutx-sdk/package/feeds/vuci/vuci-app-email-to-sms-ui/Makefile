include $(TOPDIR)/rules.mk

APP_TITLE:=VuCI UI Support for Email to SMS

ifeq (m, $(CONFIG_PACKAGE_vuci-app-email-to-sms-ui))
	APP_TLT_NAME:=Email to SMS
	APP_ROUTER:=$(TLT_PLATFORM_NAME)
	APP_APP_NAME:=email_to_sms
	APP_HW_INFO:=mobile
endif

include ../app.mk

define Package/vuci-app-email-to-sms-ui/description
	Email to SMS is a function that connects to your email account and checks its inbox at the specified frequency. 
	If it finds any new received emails with a specific subject (phone number in email subject), 
	it sends the body of the email as an SMS message(s) to the recipient specified in the email subject field.
endef

# call BuildPackage - OpenWrt buildroot signature
