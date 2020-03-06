
_echo_red()
{
	echo -e "\e[31m${@}\e[m"
}
_echo_blue()
{
	echo -e "\e[34m${@}\e[m"
}
_echo_green()
{
	echo -e "\e[32m${@}\e[m"
}
_echo_purple()
{
	echo -e "\e[35m${@}\e[m"
}

_logfile()
{
	echo /tmp/mm_pkginst.log
}

_postfile()
{
	echo /tmp/mm_pkginst_post.txt
}

_log()
{
	_echo_green "$@"
	echo "[$(date '+%F %R.%S')] [OK]    $@" >> $(_logfile)
}

_err()
{
	_echo_red "$@"
	echo "[$(date '+%F %R.%S')] [ERROR] $@" >> $(_logfile)
}

_postreg()
{
	echo "$@" >> $(_postfile)
}


_ppacheck()
{

	local ppa_added

#	echo -----
#	echo PPA $@ の登録を確認します。
#	echo
#	echo $@
#	echo 確認


#	grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep $ppa
#	ppa_added=`grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -v list.save | grep -v deb-src | grep deb | grep $@  | wc -l`

	ppa_added=$(grep ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -v list.save | grep -v deb-src |grep -v "#" | grep deb | grep $@  | wc -l)

	if [ $ppa_added -lt 1 ]; then
			echo n
			
	else
			echo y
	fi

}

_aptcheck()
{
	local i
	local pkgs

	pkgs=$(dpkg -l | grep -v ^rc | awk '{print $2}' | cut -d: -f1)

	# 一つでもインストールされていない場合はnを返す
	for i in $@ ; do
		if [ $(dpkg-query -W -f='${Status}' ${pkgs}  2>/dev/null | grep -c "ok installed") -lt 1 ]; then
			echo n
			return 0
		fi
	done
	echo y

}


#_aptsrccheck()
#{
#
#	local  aptsrc
#	
#	aptsrc=$( grep -r --include '*.list' '^deb ' /etc/apt/sources.list* | grep grep $@ )
#	
#	# 一つでもインストールされていない場合はnを返す
#	
#	for i in $@ ; do
#		if [ (echo $aptsrc | wc -l) -lt 1 ]; then
#			echo n
#			return 0
#		fi
#	done
#	echo y
#
#}
#


_check()
{
	local i
	local pkgs
#	local cache=/tmp/_mm_pkginst_dpkg
	
#	if [ -f "${cache}"] ; then
#		pkgs=$(cat "${cache}")
#	else
		pkgs=$(dpkg -l | grep -v ^rc | awk '{print $2}' | cut -d: -f1)
#		echo "${pkgs}" > "${cache}"
#	fi

	# 一つでもインストールされていない場合はnを返す
	for i in $@ ; do
		if [ $(echo "${pkgs}" | grep "^${i}$" | wc -l) -lt 1 ] ; then
			echo n
			return 0
		fi
	done
	echo y
}

_clean()
{
	echo -----
	echo 不要になったパッケージとキャッシュと消去します。
	echo 
	
	if sudo apt-get autoremove ; then
		_log "不要パッケージのアンインストールに成功しました。"
	else
		_err "不要パッケージのアンインストールに失敗しました。"
		exit 1
	fi
	
	sudo dpkg --purge $(dpkg -l | grep ^rc | cut -f3 -d " ") 2>/dev/null
	sudo apt-get autoclean
	sudo apt-get clean
	echo
	return 0
}

_update()
{
	local tempfile=/tmp/$(mktemp XXXXXXXX)
	
	echo -----
	echo データベースを最新の状態に更新します。
	sudo apt-get update | tee ${tempfile}
	
	if [ $(cat ${tempfile} | grep "エラー" | wc -l) -lt 10 ] ; then
		_log "パッケージデータベースの更新に成功しました。"
	else
		_err "パッケージデータベースのダウンロードに失敗しました。"
		return 1
	fi
	rm -f ${tempfile}
	
	sudo apt-get autoclean
	sudo apt-get clean
	echo
	return 0
}

_install()
{
	echo -----
	echo パッケージ $@ をインストールします。
	echo
	echo $@
	echo 確認
	
	if sudo apt-get install --no-install-recommends $@ ; then
		_log "$@ のインストールに成功しました。"
	else
		_err "$@ のインストールに失敗しました。"
		exit 1
	fi
	
	echo
	return 0
}

_debinstall()
{
	cd /tmp
	echo -------
	echo debパッケージ $@ をインストールします。
	echo
	echo $@
	echo 確認
#パッケージ名を抽出する。
	target=$@
	deb=${target##*/}

#ダウンロードする
	if wget -c  $target ; then
		_log "$debのダウンロードに成功しました。"
	else
		_err "$debのダウンロードに失敗しました。"
	
	fi
		
#インストール	
	if sudo dpkg -i $deb  ; then
		_log "$debインストールに成功しました。"
	else
		sudo apt update --fix-missing
		if sudo apt install --fix-broken ; then
			_log "$debインストールに成功しました。"
		else
			_err "$debのインストールに失敗しました。"

		fi

	fi

	_log "一時ファイルを除去しています..."
	rm -f $deb
}


_ppainstall()
{
	echo -----
	echo PPA $@ を登録します。
	echo
	echo $@
	echo 確認
	
	if sudo add-apt-repository  "ppa:${@}" ; then
		_log "$@ の登録に成功しました。"
	else
		_err "$@ の登録に失敗しました。"
		exit 1
	fi

#	sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com `sudo apt update 2>&1 | grep -o '[0-9A-Z]\{16\}$' | xargs`
	
	sudo apt update

	echo
	return 0
}




_purge()
{
	echo -----
	echo パッケージ $@ をアンインストールします。
	echo
	
	if sudo apt-get purge $@ ; then
		_log "$@ のアンインストールに成功しました。"
	else
		_err "$@ のアンインストールに失敗しました。"
		exit 1
	fi
	
	echo
	return 0
}


_ppapurge()
{
	echo -----
	echo PPA $@ を削除します。
	echo
	echo $@
	echo 確認

	echo  "PPAを削除すると関係するアプリケーションも削除される時があります。"
	echo  "PPAは、後で、y-ppa managerを利用して削除できます。"
	echo  "PPAを削除する場合は、"y" 削除しない場合は、"n"を入力してください。"

	#Yes No の質問をします。
	if _ask_yes_no "よろしいですか？"; then

	# 「Yes」の時の処理

		echo "ppa:${@}を削除します。"
#		if sudo add-apt-repository --remove  "ppa:${@}" ; then
		if sudo ppa-purge  "ppa:${@}" ; then

			_log "$@ の削除に成功しました。"
		else
			_err "$@ の削除に失敗しました。"
		exit
		fi

	else
	# 「No」の時の処理
		_log "ppa:${@}を残します。削除は Y-PPA Managerなどを使用してください。"

	fi


	echo
	return 0

}


_ask_yes_no ()
{
  while true; do
    echo -n "$* [y/n]: "
    read ANS
    case $ANS in
      [Yy]*)
        return 0
        ;;  
      [Nn]*)
        return 1
        ;;
      *)
        echo "yまたはnを入力してください"
        ;;
    esac
  done
}


_desktop()
{
	local desktop
	desktop=$(eval echo $(cat "${HOME}/.config/user-dirs.dirs" | grep ^XDG_DESKTOP_DIR= | grep -o '=.*$' | sed -e 's/"//igm' -e 's/=//igm'))
	if [ ! "$desktop" == "" ] ; then
		echo "$desktop"
	else
		if [ -d "$HOME/デスクトップ" ] ; then
			echo "$HOME/デスクトップ"
		elif [ -d "$HOME/Desktop" ] ; then
			echo "$HOME/Desktop"
		elif [ -d "$HOME/ドキュメント" ] ; then
			echo "$HOME/ドキュメント"
		elif [ -d "$HOME/Documents" ] ; then
			echo "$HOME/Documents"
		else
			echo "$HOME"
		fi
	fi
}

_tmppkg_list()
{
	echo /tmp/mm_pkginst_tmppkg.txt
}

_tmppkg_inst()
{
	local i
	local pkgs
	local inst
	
	pkgs=$(dpkg -l | grep -v ^rc | awk '{print $2}')
	
	for i in $@ ; do
		if [ $(echo "${pkgs}" | grep "${i}" | wc -l) -lt 1 ] ; then
			inst="${inst} ${i}"
			echo "${i}" >> $(_tmppkg_list)
		fi
	done
	
	_log "一時的に必要とされるパッケージ ${inst} をインストールします。"
	sudo apt-get install -y ${inst}
}

_tmppkg_uninst()
{
	local i
	local pkgs
	
	if [ -f $(_tmppkg_list) ] ; then
		pkgs=$(echo $(cat $(_tmppkg_list) | sort | uniq))
		
		_log "一時的に使用されていたパッケージ ${pkgs} をアンインストールします。"
		sudo apt-get purge -y ${pkgs}
		sudo apt-get autoremove -y
		rm -f $(_tmppkg_list)
	fi
}

_ismanual()
{
	local ret
	ret=$(echo "$(apt-cache policy ${1})" | grep "\*\*\*" -B0 -A2 | grep / )
	
	if [ $(echo "${ret}" | grep ://           | wc -l) -lt 1 ] && \
	   [ $(echo "${ret}" | grep /var/lib/dpkg | wc -l) -gt 0 ] ; then
		echo y
	else
		echo n
	fi
}

_reinst_from_apt()
{
	local ver
	local pkgs
	
	for i in $@ ; do
		if [ "$(_ismanual ${i})" == "n" ] ; then
			continue
		else
			ver=$(echo "$(apt-cache policy ${i})" | grep :// -m 1 -B 2 | \
				grep -v ":$" | grep -v :// | grep -v /var/lib/dpkg | grep -o "\S*\s*\S*$" | cut -d\  -f1)
			pkgs="${pkgs} ${i}=${ver}"
		fi
	done
			
	if sudo apt-get install -y --force-yes ${pkgs} ; then
		_log "${pkgs} をAPTリポジトリから再度インストールしました。"
	else
		_err "${pkgs} をAPTリポジトリからインストールできませんでした。"
	fi
}

