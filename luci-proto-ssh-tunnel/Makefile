include $(TOPDIR)/rules.mk

PKG_NAME:=luci-proto-ssh-tunnel
PKG_VERSION:=0.1.2
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-proto-ssh-tunnel
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=Protocols
	TITLE:=SSH Tunnel netifd protocol
	DEPENDS:=+luci-base +netifd +kmod-tun +openssh-client +sshpass +python3-light
	PKGARCH:=all
endef

define Package/luci-proto-ssh-tunnel/description
LuCI and netifd protocol for the SSH Tunnel VPN client.
endef

define Build/Compile
endef

define Package/luci-proto-ssh-tunnel/install
	$(INSTALL_DIR) $(1)/lib/netifd/proto
	$(INSTALL_BIN) ./files/ssh_tunnel.sh $(1)/lib/netifd/proto/ssh_tunnel.sh
	$(INSTALL_DIR) $(1)/usr/libexec
	$(INSTALL_BIN) ./files/ssh-tunnel-client.py $(1)/usr/libexec/ssh-tunnel-client
	$(INSTALL_DIR) $(1)/usr/share/ssh-tunnel
	$(INSTALL_DATA) ./files/install-server.sh $(1)/usr/share/ssh-tunnel/install-server.sh
	$(INSTALL_DIR) $(1)/www/luci-static/resources/protocol
	$(INSTALL_DATA) ./files/ssh-tunnel.js $(1)/www/luci-static/resources/protocol/ssh_tunnel.js
endef

$(eval $(call BuildPackage,luci-proto-ssh-tunnel))
