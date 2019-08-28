function get_cookie(name)
{
	with(document.cookie)
	{
		var index=indexOf(name+"=");
		if(index==-1) return '';
		index=indexOf("=",index)+1;
		var endstr=indexOf(";",index);
		if(endstr==-1) endstr=length;
		return unescape(substring(index,endstr));
	}
};

function get_password(name)
{
	var pass=get_cookie(name);
	if(pass) return pass;

	var chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
	var pass='';

	for(var i=0;i<8;i++)
	{
		var rnd=Math.floor(Math.random()*chars.length);
		pass+=chars.substring(rnd,rnd+1);
	}

	return(pass);
}
