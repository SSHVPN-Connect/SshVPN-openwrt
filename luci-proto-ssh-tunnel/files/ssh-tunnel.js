'use strict';
'require form';
'require network';

return network.registerProtocol('ssh_tunnel', {
	getI18n: function() { return _('SSH Tunnel'); },
	getIfname: function() { return this._ubus('l3_device') || 'sshvpn0'; },
	getPackageName: function() { return 'network'; },
	isFloating: function() { return false; },
	isVirtual: function() { return true; },
	getDevices: function() { return [ this.getOption('device') || 'sshvpn0' ]; },
	renderFormOptions: function(s) {
		var o;
		o = s.taboption('general', form.Value, 'server', _('SSH server'));
		o.rmempty = false;
		o.placeholder = 'vpn.example.com';
		o = s.taboption('general', form.Value, 'port', _('SSH port'));
		o.datatype = 'port';
		o.default = '22';
		o = s.taboption('general', form.Value, 'username', _('SSH user'));
		o.rmempty = false;
		o.placeholder = 'root';
		o.description = _('Root SSH login is required for automatic server setup.');
		o = s.taboption('general', form.Value, 'identity_file', _('Private key file'));
		o.placeholder = '/etc/dropbear/id_ed25519';
		o.description = _('The private key must already exist on the router and be readable by root.');
		o = s.taboption('general', form.Value, 'password', _('SSH password'));
		o.password = true;
		o.rmempty = true;
		o = s.taboption('general', form.Value, 'device', _('Tunnel device'));
		o.default = 'sshvpn0';
		o.rmempty = true;
	}
});
