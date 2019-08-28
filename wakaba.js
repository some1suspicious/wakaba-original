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

function set_cookie(name,value,days)
{
	if(days)
	{
		var date=new Date();
		date.setTime(date.getTime()+(days*24*60*60*1000));
		var expires="; expires="+date.toGMTString();
	}
	else expires="";
	document.cookie=name+"="+value+expires+"; path=/";
}

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



function set_stylesheet(styletitle,norefresh)
{
	set_cookie("wakabastyle",styletitle,365);

	var links=document.getElementsByTagName("link");
	var found=false;
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title)
		{
			links[i].disabled=true; // IE needs this to work. IE needs to die.
			if(styletitle==title) { links[i].disabled=false; found=true; }
		}
	}
	if(!found) set_preferred_stylesheet();

/*	if(!norefresh)
	{
		var images=document.images; //getElementsByTagName("img");
		for(var i=0;i<images.length;i++)
		{
			var classname=images[i].getAttribute('class');
			if(classname&&classname.indexOf('captcha')!=-1)
			{
				//var src=images[i].src+"";
				images[i].src=images[i].src;
				//images[i].src=src+"&c";
			}
		}
	}*/
}

function set_preferred_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title) links[i].disabled=(rel.indexOf("alt")!=-1);
	}
}

function get_active_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&title&&!links[i].disabled) return title;
	}
	return null;
}

function get_preferred_stylesheet()
{
	var links=document.getElementsByTagName("link");
	for(var i=0;i<links.length;i++)
	{
		var rel=links[i].getAttribute("rel");
		var title=links[i].getAttribute("title");
		if(rel.indexOf("style")!=-1&&rel.indexOf("alt")==-1&&title) return title;
	}
	return null;
}

/*window.onload=function(e)
{
	var cookie=get_cookie("wakabastyle");
	var title=cookie?cookie:get_preferred_stylesheet();
	set_stylesheet(title);
}*/

window.onunload=function(e)
{
	var title=get_active_stylesheet();
	if(title) set_cookie("wakabastyle",title,365);
}

var cookie=get_cookie("wakabastyle");
var title=cookie?cookie:get_preferred_stylesheet();
set_stylesheet(title,true);



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
