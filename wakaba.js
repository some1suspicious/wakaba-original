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

function insert(text) /* hay WTSnacks what's goin on in this function? */
{
	var textarea=document.forms[0].comment;
	if(textarea)
	{
		if(textarea.createTextRange && textarea.caretPos)
		{
			var caretPos=textarea.caretPos;
			caretPos.text=caretPos.text.charAt(caretPos.text.length-1)==" "?text+" ":text;
		}
		else
		{
			textarea.value+=text+" ";
		}
		textarea.focus();
	}
}

window.onload=function(e)
{
	var index=document.location.toString().indexOf("#");

	if(index!=-1)
	{
		var num=document.location.toString().substring(index+1);
		var reply=document.getElementById("reply"+num);
		if(reply) reply.className="highlight";
	}
}
