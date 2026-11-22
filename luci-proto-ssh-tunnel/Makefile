include $(TOPDIR)/rules.mk

LUCI_TITLE:=SSH Tunnel netifd protocol
LUCI_DEPENDS:=+luci-base +netifd +kmod-tun +openssh-client +sshpass +python3-light
LUCI_PKGARCH:=all
PKG_NAME:=luci-proto-ssh-tunnel
PKG_VERSION:=0.1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/luci.mk

define Package/luci-proto-ssh-tunnel/install
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/ssh_tunnel.sh $(1)/lib/netifd/proto/ssh_tunnel.sh
	$(INSTALL_DIR) $(1)/usr/libexec
$(INSTALL_BIN) ./files/ssh-tunnel-client.py $(1)/usr/libexec/ssh-tunnel-client
	$(INSTALL_DIR) $(1)/usr/share/ssh-tunnel
	$(INSTALL_DATA) ./files/install-server.sh $(1)/usr/share/ssh-tunnel/install-server.sh
	$(INSTALL_DIR) $(1)/www/luci-static/resources/protocol
	$(INSTALL_DATA) ./files/ssh-tunnel.js $(1)/www/luci-static/resources/protocol/ssh-tunnel.js
endef

$(eval $(call BuildPackage,luci-proto-ssh-tunnel))
