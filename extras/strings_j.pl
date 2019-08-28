use encoding "shift-jis";

use constant S_HOME => 'ホーム';
use constant S_ADMIN => '管理用';
use constant S_RETURN => '掲示板に戻る';
use constant S_POSTING => 'レス送信モード';

use constant S_NAME => 'おなまえ';
use constant S_EMAIL => 'E-mail';
use constant S_SUBJECT => '題　　名';
use constant S_SUBMIT => '送信する';
use constant S_COMMENT => 'コメント';
use constant S_UPLOADFILE => '添付File';
use constant S_NOFILE => '画像なし';
use constant S_CAPTCHA => 'Verification';
use constant S_DELPASS => '削除キー';
use constant S_DELEXPL => '(記事の削除用。英数字で8文字以内)';
use constant S_RULES => '<ul><li>添付可能ファイル：GIF, JPG, PNG ブラウザによっては正常に添付できないことがあります。</li>'.
                        '<li>最大投稿データ量は '.MAX_KB.' KB までです。sage機能付き。</li>'.
                        '<li>画像は横 '.MAX_W.'ピクセル、縦 '.MAX_H.'ピクセルを超えると縮小表示されます。</li></ul>';

use constant S_THUMB => 'サムネイルを表示しています.クリックすると元のサイズを表示します.';
use constant S_NOTHUMB => 'No<br />thumbnail';
use constant S_PICNAME => '画像タイトル：';
use constant S_REPLY => '返信';
use constant S_OLD => 'このスレは古いので、もうすぐ消えます。';
use constant S_ABBR => 'レス%d件省略。全て読むには返信ボタンを押してください。';

use constant S_REPDEL => '【記事削除】';
use constant S_DELPICONLY => '画像だけ消す';
use constant S_DELKEY => '削除キー';
use constant S_DELETE => '削除';

use constant S_PREV => '前のページ';
use constant S_FIRSTPG => '最初のページ';
use constant S_NEXT => '次のページ';
use constant S_LASTPG => '最後のページ';
use constant S_FOOT => '- <a href="http://php.s3.to">GazouBBS</a>'.
	               ' + <a href="http://www.2chan.net/">futaba</a>'.
	               ' + <a href="http://www.1chan.net/futallaby/">futallaby</a>'.
	               ' + <a href="http://wakaba.c3.cx/">wakaba</a> -';

use constant S_RELOAD => 'リロード';
use constant S_MANAGEMENT => '削除';
use constant S_DELETION => '削除';
use constant S_WEEKDAYS => ('日','月','火','水','木','金','土');
#define(S_SCRCHANGE, '画面を切り替えます');

use constant S_MANARET => '掲示板に戻る';
use constant S_MANAUPD => 'ログを更新する';
use constant S_MANAMODE => '管理モード';
use constant S_MANAPANEL => '記事削除';
use constant S_MANABANS => 'Bans';
use constant S_MANAPOST => '管理人投稿';
use constant S_MANAREBUILD => 'Rebuild caches';
use constant S_MANANUKE => 'Nuke board';
use constant S_MANASUB => ' 認証';

use constant S_NOTAGS => 'タグがつかえます';

use constant S_MPTITLE => '削除したい記事のチェックボックスにチェックを入れ、削除ボタンを押して下さい。';
use constant S_MPDELETEIP => 'Delete all';
use constant S_MPDELETE => '削除する';
use constant S_MPRESET => 'リセット';
use constant S_MPONLYPIC => '画像だけ消す';
use constant S_MPDELETEALL => 'Del all';
use constant S_MPBAN => 'Ban';
use constant S_MPTABLE => '<th>Delete?</th><th>Post No.</th><th>Time</th><th>Subject</th>'.
                          '<th>Name</th><th>Comment</th><th>IP</th><th>Filename<br />(Size)</th>'.
                          '<th>MD5</th>';
#define(S_MDTABLE1, '<th>削除</th><th>記事No</th><th>投稿日</th><th>題名</th>');
#define(S_MDTABLE2, '<th>投稿者</th><th>コメント</th><th>ホスト名</th><th>添付<br />(Bytes)</th><th>md5</th>');
use constant S_IMGSPACEUSAGE => '【 画像データ合計 : <b>%d</b> KB 】';

use constant S_BANTITLE => 'Ban Panel';
use constant S_BANTABLE => '<th>Type</th><th>Value</th><th>Comment</th><th>Action</th>';
use constant S_BANIPLABEL => 'IP';
use constant S_BANMASKLABEL => 'Mask';
use constant S_BANCOMMENTLABEL => 'Comment';
use constant S_BANWORDLABEL => 'Word';
use constant S_BANIP => 'Ban IP';
use constant S_BANWORD => 'Ban word';
use constant S_BANWHITELIST => 'Whitelist';
use constant S_BANREMOVE => 'Remove';
use constant S_BANCOMMENT => 'Comment';
#define(S_RESET, 'リセット');

use constant S_TOOBIG => 'アップロードに失敗しました<br />サイズが大きすぎます<br />'.MAX_KB.'Kバイトまで';
use constant S_TOOBIGORNONE => 'アップロードに失敗しました<br />画像サイズが大きすぎるか、<br />または画像がありません。';
use constant S_REPORTERR => '該当記事がみつかりません';
use constant S_UPFAIL => 'アップロードに失敗しました<br />サーバがサポートしていない可能性があります';
use constant S_NOREC => 'アップロードに失敗しました<br />画像ファイル以外は受け付けません';
#use constant S_SAMEPIC => 'アップロードに失敗しました<br />同じ画像がありました';
use constant S_NOCAPTCHA => 'Error: No verification code on record - it probably timed out.';
use constant S_BADCAPTCHA => 'Error: Wrong verification code entered.';
use constant S_BADFORMAT => 'Error: File format not supported.';
use constant S_STRREF => '拒絶されました(str)';
use constant S_UNJUST => '不正な投稿をしないで下さい(post)';
use constant S_NOPIC => '画像がありません';
use constant S_NOTEXT => '何か書いて下さい';
use constant S_TOOLONG => '本文が長すぎますっ！';
use constant S_NOTALLOWED => 'Error: Posting not allowed.';
use constant S_UNUSUAL => '異常です';
use constant S_BADHOST => '拒絶されました(host)';
use constant S_RENZOKU => '連続投稿はもうしばらく時間を置いてからお願い致します';
use constant S_RENZOKU2 => '画像連続投稿はもうしばらく時間を置いてからお願い致します';
use constant S_RENZOKU3 => '連続投稿はもうしばらく時間を置いてからお願い致します';
use constant S_PROXY => 'ＥＲＲＯＲ！　公開ＰＲＯＸＹ規制中！！(%d)';
use constant S_DUPE => 'アップロードに失敗しました<br />同じ画像があります';
use constant S_NOTHREADERR => 'スレッドがありません';
use constant S_BADDELPASS => '該当記事が見つからないかパスワードが間違っています';
use constant S_WRONGPASS => 'パスワードが違います';
#define(S_CANNOTWRITE, 'カレントディレクトリに書けません<br />');
use constant S_NOTWRITE => 'を書けません<br />';
#define(S_NOTREAD, 'を読めません<br />');
#define(S_NOTDIR, 'がありません<br />');

use constant S_SQLCONF => '接続失敗';
use constant S_SQLFAIL => 'sql失敗<br />';
#define(S_SQLDBSF, 'mysql_select_db失敗<br />');
#define(S_TCREATE, 'テーブルを作成します<br />\n');
#define(S_TCREATEF, 'テーブル作成失敗<br />');

#define(S_UPGOOD, '画像 $upfile_name のアップロードが成功しました<br /><br />');

#define(S_ANONAME, '名無し');
#define(S_ANOTEXT, '本文なし');
#define(S_ANOTITLE, '無題');

no encoding;
1;