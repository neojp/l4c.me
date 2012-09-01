/* Use this script if you need to support IE 7 and IE 6. */

window.onload = function() {
	function addIcon(el, entity) {
		var html = el.innerHTML;
		el.innerHTML = '<span style="font-family: \'entypo\'">' + entity + '</span>' + html;
	}
	var icons = {
			'icon-untitled' : '&#x2a;',
			'icon-untitled-2' : '&#x2b;',
			'icon-untitled-3' : '&#x30;',
			'icon-untitled-4' : '&#x3a;',
			'icon-untitled-5' : '&#x3b;',
			'icon-untitled-6' : '&#x3c;',
			'icon-untitled-7' : '&#x3e;',
			'icon-untitled-8' : '&#x42;',
			'icon-untitled-9' : '&#x2c;',
			'icon-untitled-10' : '&#x2d;',
			'icon-untitled-11' : '&#x49;',
			'icon-untitled-12' : '&#x4f;',
			'icon-untitled-13' : '&#x4e;',
			'icon-untitled-14' : '&#x4c;',
			'icon-untitled-15' : '&#x50;',
			'icon-untitled-16' : '&#x53;',
			'icon-untitled-17' : '&#x55;',
			'icon-untitled-18' : '&#x57;',
			'icon-untitled-19' : '&#x58;',
			'icon-untitled-20' : '&#x63;',
			'icon-untitled-21' : '&#x66;',
			'icon-untitled-22' : '&#x67;',
			'icon-untitled-23' : '&#x22;',
			'icon-untitled-24' : '&#x23;',
			'icon-untitled-25' : '&#x24;',
			'icon-untitled-26' : '&#x26;',
			'icon-untitled-27' : '&#x27;',
			'icon-untitled-28' : '&#x28;',
			'icon-untitled-29' : '&#x29;',
			'icon-untitled-30' : '&#x2f;',
			'icon-untitled-31' : '&#x52;',
			'icon-untitled-32' : '&#x40;',
			'icon-untitled-33' : '&#x5a;',
			'icon-untitled-34' : '&#x21;',
			'icon-untitled-35' : '&#x31;',
			'icon-untitled-36' : '&#x32;',
			'icon-untitled-37' : '&#x33;',
			'icon-untitled-38' : '&#x25;',
			'icon-untitled-39' : '&#xf00e;',
			'icon-untitled-40' : '&#xf010;',
			'icon-untitled-41' : '&#xf014;',
			'icon-untitled-42' : '&#xf073;',
			'icon-untitled-43' : '&#xf086;',
			'icon-untitled-44' : '&#xf015;',
			'icon-write' : '&#xe000;'
		},
		els = document.getElementsByTagName('*'),
		i, attr, html, c, el;
	for (i = 0; i < els.length; i += 1) {
		el = els[i];
		attr = el.getAttribute('data-icon');
		if (attr) {
			addIcon(el, attr);
		}
		c = el.className;
		c = c.match(/icon-[^\s'"]+/);
		if (c) {
			addIcon(el, icons[c[0]]);
		}
	}
};