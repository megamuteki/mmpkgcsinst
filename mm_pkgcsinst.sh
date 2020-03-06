#!/bin/bash

######################################################
#二重起動回避

PROCNAME=$(basename $0);
PROCID=$(pidof -x $PROCNAME)
if [ $(echo $PROCID | awk '{print NF}') -gt 1 ];
then
  # sciript is already runnning.
  exit 0;
fi

######################################################
# システムのアップデートと必要なライブラリなどのインストール
#leafpad, thunar, yad, git, build-essential, \n fdupes, ppa-purgeの確認とインストールをします。
#######################################################

#.txt以外のファイルに実行許可を与える。
#ls | grep -v -E 'txt$' | xargs sudo chmod +x
#ls | grep -v -E 'txt$' | xargs sudo umaxk a+x


x-terminal-emulator -e bash -c  $(pwd)/mm_pkgcsinst_files/00startup

startuppid=$(ps --no-heading -C  00startup  -o pid)

tail -f /dev/null --pid=$startuppid; echo "go"

######################################################
#   リストモードの選択とリストの作成
#######################################################
#選択したメニューからパッケージリストを作成する。
_genpkglist()
{
datadir=$(cd $(dirname "$0") && pwd)/mm_pkgcsinst_files

#Cancelした時の一時ファイルを削除
file_before="/tmp/_pkginstall_before"
file_after="/tmp/_pkginstall_after"
file_dislplay="/tmp/_pkginstall_display"


if [ -e $file_before ]; then
    rm -f $file_before
fi

if [ -e $file_after ]; then
    rm -f $file_after
fi

if [ -e $file_display ]; then
    rm -f $file_display
fi



#どのパッケージリストを使用するかを選択する。
listflag=$(yad \
--title="mm-pkginstaller" \
--width="640" \
--height="600" \
--on-top \
--center \
--form --scroll \
--text  "<span foreground='blue'><big><b>------利用するパッケージリストを選択してください。------</b></big></span>"  \
--button="gtk-cancel":1 \
--form  \
--field="\
Linux FEREN OS 2020 及び　Mint 19.2 XFCE を利用する方向けになります。\n\
Adobe CS の　Substitute (代役）のようなアプリの試験用\n\
インストールスクリプトになります。\n\
Linux Bean インストーラスクリプトを利用しています。\n\
　　　":LBL 'bash -c ""' \
--field="\
<span foreground='green'><big>-----Adobe Alternative（代役）グループ１-----</big></span>":FBTN  'bash -c " echo 21 ; kill -USR1 $YAD_PID"' \
--field="\
Photoshop, Illustrator, ClipStudio, SAI, \n\
InDesign, Animate, Premiere, \n\
　　　":LBL 'bash -c ""' \
--field="\
<span foreground='green'><big>-----Adobe Alternative（代役）グループ２-----</big></span>":FBTN 'bash -c " echo 22 ; kill -USR1 $YAD_PID"' \
--field="\
After Effect, Light Room, Dream Weaver, Acrobat, Encore, InCopy, Audition \n\
Encore, InCopy, Audition  \n\
　　":LBL 'bash -c ""' \
--field="\
<span foreground='green'><big>----ペンタブツール-----（PentabTools）</big></span> ":FBTN 'bash -c " echo 23 ; kill -USR1 $YAD_PID"' \
--field="\
ペンタブ関連のツール類になります。\n\
XP-PEN製品のペンタブレットが基本になっています。\n\
ペンタブレットドライバ類\n\
ペンタブ関連のツール類\n\
　":LBL 'bash -c ""' \
--field="\
<span foreground='green'><big>-----便利ツール-----</big></span>":FBTN 'bash -c " echo 24 ; kill -USR1 $YAD_PID"' \
--field="\
ファイル検索、コーデックなど、便利なユーティリティ類になります。\n\
安定な環境を利用する方は、区分APTのみをご利用ください。\n\
　":LBL 'bash -c ""' \
--field="\
<span foreground='green'><big>---萌え化スクリプト---</big></span>":FBTN 'bash -c " echo 25 ; kill -USR1 $YAD_PID"' \
--field="\
萌え化スクリプト類になります。\n\
説明は。http://moebuntu.web.fc2.com/moehowto.htmlを参照ください。\n\
デスクトップを萌化する場合ご利用ください。\n\
　":LBL 'bash -c ""' \
  2>/dev/null )


listflag=$(echo $listflag  | sed -e 's/[^0-9]//g') 



case  $listflag in
 
     21)
		cat   $datadir/01catalogcsa.txt >  $datadir/00pkgcatalog.txt
		
         ;;
     22) 
          
		cat  $datadir/01catalogcsb.txt > $datadir/00pkgcatalog.txt
		
		;;                 
     23) 
        
		cat  $datadir/01catalogpen.txt > $datadir/00pkgcatalog.txt
		
		;;
     24) 
          
		cat  $datadir/01catalogutil.txt > $datadir/00pkgcatalog.txt
		
		;;
     25) 
          
		cat  $datadir/01catalogmoe.txt > $datadir/00pkgcatalog.txt
		
		;;
	 * )
	    exit 0
	    
		;;
		
esac         



}


######################################################
#   変数の準備
#######################################################

_prepvar()
{
#Pkgリストに変換するテキストファイルの場所とファイル名
#datadir=$(cd $(dirname "$0") && pwd)/mm_pkgcsinst_files
catalog=$(cat ${datadir}/00pkgcatalog.txt)

#解説文
infotxt=${datadir}/00infotxt.txt

#catalogファイル
catalogppa=${datadir}/01catalogcsb.txt
catalogapt=${datadir}/01catalogcsa.txt
catalogpen=${datadir}/01catalogpen.txt
catalogmoe=${datadir}/01catalogmoe.txt
catalogutil=${datadir}/01catalogutil.txt


# 共通関数の読み込み
. ${datadir}/00common.fnc

# テキストファイルの行数（ループの脱出判定に使用）
linecount=$(echo "$catalog" | wc -l)

# 表示に使用するリスト
display=""

# 変更箇所の検出に使用するリスト
before=""

# 改行
BR="
"
}

#######################################################
#  テキストファイルをリスト形式に変換
#######################################################

#表示と比較に必要なリストを作成する。
_txt2list()
{
	echo 0
	
	rm -f "/tmp/_pkginstall_display"
	rm -f "/tmp/_pkginstall_before"
	rm -f "/tmp/_pkginstall_neterr"


	#ネットワークの通信状況の確認	
	wget -qq --spider -t 1 -T 10 google.com
	if [ $? -gt 0 ] ; then
		touch "/tmp/_pkginstall_neterr"
		return 1
	fi
	
	# 区切り文字を改行に
	_IFS="$IFS";IFS="$BR"
	
	# パッケージカタログからリストを作成
	i=0
	while [ $linecount -gt $i ] ; do
		
		# 必要な情報を取り出す
		name=$(echo "$catalog" | sed -n "$(expr $i + 1)p")
		pow=$( echo "$catalog" | sed -n "$(expr $i + 2)p")
		method=$( echo "$catalog" | sed -n "$(expr $i + 3)p")
		desc=$(echo "$catalog" | sed -n "$(expr $i + 4)p")
		id=$(  echo "$catalog" | sed -n "$(expr $i + 5)p")
		
		# 表示用と比較用の二つのリストを生成する
		display="${display}$(${datadir}/${id} -c)${BR}${name}${BR}${pow}${BR}${method}${BR}${desc}${BR}${id}${BR}"
		before="${before}$(${datadir}/${id} -c)|${name}|${pow}|${method}|${desc}|${id}|${BR}"
		i=$(expr $i + 6)
		
	done
	
	# 区切り文字を戻す
	IFS="$_IFS"
	
	echo "${display}" > "/tmp/_pkginstall_display"
	echo "${before}"  > "/tmp/_pkginstall_before"
	
	return 0
}

_makelist()
{


_txt2list | \
yad --progress --title="起動中" --on-top --center --window-icon=checkbox --image=checkbox \
--text "インストール状態を確認しています..." --pulsate --auto-close


# ネットワーク接続が確認できない場合は、設定パネルを出して終了する
if [ -f "/tmp/_pkginstall_neterr" ] ; then
	rm -f "/tmp/_pkginstall_neterr"
	nohup yad --title="エラー" --on-top --center --window-icon=checkbox --image=checkbox \
	--text "インターネットに接続できていません" >/dev/null 2>&1 &
	nohup nm-connection-editor >/dev/null 2>&1 &
	nohup mm_proxy >/dev/null 2>&1 &
	exit 1
fi


display=$(cat "/tmp/_pkginstall_display")
before=$(cat  "/tmp/_pkginstall_before")

# 一時ファイルを削除
rm -f "/tmp/_pkginstall_display"
rm -f "/tmp/_pkginstall_before"

}


#リストを表示する。
_dispList()
{
ipcrm --all=shm
fkey=$(($RANDOM * $$))

after=$(
	echo "$display" | yad \
	--plug="$fkey" --tabnum=1 \
	--list --checklist --hide-column="6" \
	--text="導入したい機能にチェックを入れてください（チェックを外したものは削除されます）。" \
	--column="導入" --column="パッケージ名" --column="ALT区分" --column="ソース" --column="説明" --column="ID" &

	yad --plug="$fkey" --tabnum=2 \
	--text-info \
    --filename=$infotxt --fontname=Monospace 2>/dev/null &
		
	yad --key="$fkey" \
	--width="640" --height="480" --on-top --center --wrap-width=600 \
	--title="追加パッケージ設定ウィザード" --window-icon=checkbox \
	--notebook --tab="パッケージ" --tab="情報" \
	--button="gtk-quit:100" \
    --button="gtk-cancel:200" \
    --button="gtk-ok:0" 
	)
}



#######################################################
#  リストから変更したい項目を選択
#######################################################
#リストを表示
#リストを作成する

_listing()
{
_genpkglist
_prepvar
_makelist
_dispList
}

genflag=200

while  [ $genflag -eq  "200" ] 
do

_listing

 genflag=$?

done
   
# QUITした場合は終了terminal
if [ $genflag -eq 100 ] ; then
	exit 1
fi


#######################################################
#  変更箇所の検出・パース
#######################################################

# リストを比較するための一時ファイルを作成
echo "${before}" > "/tmp/_pkginstall_before"
echo "${after}"  > "/tmp/_pkginstall_after"

# 操作前のリストと操作後のリストを比較し、それぞれの変更箇所を取り出す
diff=$(diff "/tmp/_pkginstall_before" "/tmp/_pkginstall_after" | grep ^.\ TRUE\|)

# 一時ファイルを削除
rm -f "/tmp/_pkginstall_before"
rm -f "/tmp/_pkginstall_after"

if [ "${diff}" == "" ] ; then
	exit 1
fi
in=$( echo "$diff" | grep ^\> | sed -e 's/^> //')
out=$(echo "$diff" | grep ^\< | sed -e 's/^< //')


# 確認用のリストを作成・表示
if [ ! "${in}" == "" ] ; then
	in_disp=${BR}" 【インストール】"${BR}$(echo "$in" | awk -F"|" '{print "  "$2}')${BR}
else
	in_disp=""
fi
if [ ! "${out}" == "" ] ; then
	out_disp=${BR}" 【アンインストール】"${BR}$(echo "$out" | awk -F"|" '{print "  "$2}')${BR}
else
	out_disp=""
fi

yad --title="追加パッケージ設定ウィザード" --on-top --center --window-icon=checkbox --image=checkbox \
--text "${BR} 以下の変更を適用しますか？${BR}${in_disp}${out_disp} "

# キャンセルした場合は終了
if [ $? -gt 0 ] ; then
	exit 1

fi

# 処理用のリストを作成
in_list=$( echo "$in"  | awk -F"|" '{print $6}')
out_list=$(echo "$out" | awk -F"|" '{print $6}')


#######################################################
#  インストールと後処理
#######################################################

# 残りの処理は別窓に渡す
x-terminal-emulator -e "${datadir}/00doinst" "$(echo ${in_list} \| ${out_list})"
#exec  "${datadir}/00doinst" "$(echo ${in_list} \| ${out_list})"


# 終了待ち
while true ; do
	if [ $(ps alxxx | grep mm_pkgcsinst_files/00doinst | grep -v grep | \
	       grep -v thunar | grep -v leafpad | wc -l) -eq 0 ] ; then
		break
	fi
	sleep 1
done

# ログを開く
#nohup leafpad $(_logfile) &
#leafpad $(_logfile) 


# 区切り文字を改行に
_IFS="$IFS";IFS="$BR"

touch "$(_postfile)"
# ファイルに記録されたコマンドを立ち上げる
for line in $(cat "$(_postfile)") ; do
	if [ "a${line}" != "a" ] ; then
		eval nohup ${line} &
	fi
done

# 区切り文字を戻す
IFS="$_IFS"

# 記録ファイルを削除する
rm -f "$(_postfile)"
rm -f nohup.out


