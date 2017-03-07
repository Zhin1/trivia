;For newer versions or contact info check http://tatarize.nfshost.com/

;I assert no copyright, patent, trademark, or trade secret with regard to this document/script.
;Please alter, modify, butcher, edit, republish, or use this script in any way you see fit,
;with or without this text, in part or in full, without need for permission beforehand.


alias trivia.version { return 3.7 }
alias trivia.name { return Tat's Trivia Bot }
alias trivia.web { return http://tatarize.nfshost.com/ }
;########################################################
;# Direct IRC interactions.                             #
;########################################################
on *:START: { trivia.init }
on *:LOAD: {
  init.load
}
on *:INVITE:*: {
  if ($trivia.turnedoff) { return }
  if ($trivchan) { join $chan }
}
on *:JOIN:*: {
  if ($trivia.turnedoff) { return }
  inc -u5 %trivia.netsplit
  set -u3 %ident $chan
  if ((%trivia.netsplit >= 3) || (!$trivchan) || (!$getset(status,bot))) { return }
  if (($nick != $me) && (!$isdis(31))) { if ($getset(status,onjoin)) { inform $msg.trivia.onjoin } }
  elseif ($getset(status,autostart) == 1) { trivia }
  award join $nick
}
on *:INPUT:#: {
  if ($trivia.turnedoff) { return }
  if ((!$trivchan) || (/* iswm $1-)) { return }
  set -u3 %ident $chan
  if ($pre $+ * iswm $strip($1-)) { processcommand $strip($1-) }
  if ($1 == !help) { inform $msg.trivia.help }
  elseif ($question.on) { processguess $1- }

}
on *:ctcpreply:ping*:{
  if ($trivia.turnedoff) { return }
  if ($isdis(17)) return
  if (($eval(% $+ ping. $+ $nick,2)) && ($2 isnum)) {
    set -u3 %ident $eval(% $+ pingchan. $+ $nick,2)
    scid $eval(% $+ pingcid. $+ $nick) inform $msg.ping.reply
    unset % $+ ping. $+ $nick
    unset % $+ pingchan. $+ $nick
    unset % $+ pingcid. $+ $nick
    $eval(set -u $+ $slag(ping) % $+ pingantispam. $+ $nick 1,2)
  }
}
on *:TEXT:*:#:{
  if ($trivia.turnedoff) { return }
  set -u3 %ident $chan
  if (!$trivchan) return
  if ($pre $+ * iswm $strip($1-)) { processcommand $strip($1-) }
  if ($1 == !help) { inform $msg.trivia.help }
  else if (($question.on) && ($left($1,1) != /)) { processguess $1- }
}
on *:TEXT:*:?: {
  if ($trivia.turnedoff) { return }
  set -u3 %ident $chan
  if (($pre $+ $gtok(29) $+ * iswm $strip($1-)) || ($pre $+ $gtok(30) $+ * iswm $strip($1-))) { processcommand $strip($1-) }
}
;########################################################
;# Channel setup and related checks.                    #
;########################################################
alias trivchan {
  var %i = 1
  while ($tchan(%i)) {
    if (($tchan(%i,3) iswm $me) && ($tchan(%i,2) iswm $ifd($network,irc))) {
      if (($tchan(%i) iswm $chan) || ((!$chan) && ($me ison $tchan(%i)))) {
        if ($1) return $tchan(%i)
        return %i
      }
    }
    inc %i
  }
}
alias tchan { return $ifd($gettok($getset(chan,$1), $ifd($2,1), 59),$iif($2 isnum 2-3, *)) }
;########################################################
;# Menubar and submenu functions.                       #
;########################################################
menu channel,menubar {
  Trivia
  .$showon(Trivia Options):{ if (!$dialog(trivset)) { dialog -m trivset trivset } }
  .$showon(Start Trivia)
  ..$showon(Standard):{ $trivia }
  ..$showon(Unlimited Game):{ $trivia(unlimited) }
  ..$showon(Team Game):{ $trivia(team) }
  ..$showon(Theme Game)
  ...$submenu($theme.submenu($1))
  ..$showon(Specify round):{ $trivia($$?="How many question in the trivia round?") }
  .$showon(Stop Trivia):{ strivia }
  .$showon(Set Channel):{ chan.add $$chan }
  .$showon(-)
  .$showon(Features)
  ..$showon(Build Scores HTML):{ htmlbuild }
  ..$showon(Process HTML Commands):{ htmltrigger }
  ..$showon(HTML Options):{  if (!$dialog(trivbuild)) { dialog -m trivbuild trivbuild } }
  ..$showon(Themes Setup): {  if (!$dialog(triviatheme)) { dialog -m triviatheme triviatheme } }
  ..$showon(Ranks Setup): {  if (!$dialog(trivrank)) { dialog -m trivrank trivrank } }
}
alias theme.submenu {
  if (($1 == begin) || ($1 == end)) return -
  if ($getset(triviamode $+ $1, name)) return $getset(triviamode $+ $1, name) $+ : /trivia $getset(triviamode $+ $1, name)
}
menu menubar {
  Trivia
  .$showon(Force Question):{ ask }
  .$showon(Scores)
  ..$showon(Scores):{ if (!$dialog(triviascores)) { dialog -m triviascores triviascores } }
  ..$showon(Give Points): { trivia.credit $$?="Credit whom?" $$?="How many points do you wish to give, -# to remove score" }
  .$showon(Echo)
  ..$showon(Records):{ tsay $msg.trivia.records }
  ..$showon(HoF):{ tsay $msg.trivia.hof }
  ..$showon(Repeat):{ tsay $msg.question.current }
  ..$showon(Hint):{ tsay $msg.hint.hint }
  .$showon(Open)
  ..$showon(Questions):{ if $isfile($qfile(1)) { run $qfile(1) } }
  ..$showon(Additions):{ if $isfile(" $+ $triv(dir) $+ / $+ $triv(additions) $+ ") { run " $+ $triv(dir) $+ / $+ $triv(additions) $+ " } }
  ..$showon(Report):{ if $isfile(" $+ $triv(dir) $+ / $+ $triv(report) $+ ") { run " $+ $triv(dir) $+ / $+ $triv(report) $+ " } }
  .$showon(-)
  .Trivia Bot is [ $trivon ]
  ..$showon([ $trivdisflip ]) $+ :{ setset status bot $iif($getset(status,bot) == 1,0,1) }
  ..[ $trivoffflip ] $+ :{ setset status botstate $iif($getset(status,botstate) == 1,0,1) }
  .-
  .Trivia Unload:{ if ($?!="Really Unload?") { unload -rs $script } }
}
menu nicklist {
  $showon(Trivia)
  .$showon(Control)
  ..$showon(Ban):{ tban $$1 }
  ..$showon(Unban):{ tunban $$1 }
  .$showon(Add as Friend): { triviafriend.add $address($$1,7) }
  .$showon(Credit)
  ..$showon(Award)
  ...$showon(1): { trivia.credit $$1 1 }
  ...$showon(5): { trivia.credit $$1 5 }
  ...$showon(10): { trivia.credit $$1 10 }
  ..$showon(Deduct)
  ...$showon(1): { trivia.credit $$1 -1 }
  ...$showon(5): { trivia.credit $$1 -5 }
  ...$showon(10): { trivia.credit $$1 -10 }
  ..$showon(Input Amount): { trivia.credit $$1 $$?="How many points do you wish to give, -# to remove score" }
}
alias showon { if ($getset(status,botstate) != 1) return $1- }
alias trivia.turnedoff { if ($getset(status,botstate) == 1) return $true }
;########################################################
;# Menubar related, aliases.                            #
;########################################################
alias trivia.team.credit {
  if (($team) && ($2 isnum)) {
    var %list $get.showteams($1)
    var %amount $2
    var %j $numtok(%list,32)
    while (%j >= 1) {
      var %name.teammate $gettok(%list,%j,32)
      setvar %name.teammate score $calc($getvar(%name.teammate,score) + %amount)
      process.scores.time %name.teammate %amount
      dec %j
    }
  }
}
alias trivia.credit {
  if ($2 isnum) {
    setvar $1 score $calc($getvar($1,score) + $2)
    process.scores.time $1 $2
    tsay $iif($2 >= 0,$msg.trivia.awarded($1,$2),$msg.trivia.deducted($1,$2))
  }
}
alias -l trivon { return $iif($getset(status,botstate),Off,$iif($getset(status,bot),$iif($trivia.paused,Paused,Enabled), Disabled)) }
alias -l trivdisflip { return $iif($getset(status,bot),Disable,Enable) }
alias -l trivoffflip { return $iif($getset(status,botstate),On,Off) }
alias -l trivia.chan { return $iif($trivchan, Yes, No) }
alias -l trivia.dir { return $iif($isdir(" $+ $triv(dir) $+ "), Yes, No) }
alias -l trivia.file { return $iif($isfile($qfile(1)), Yes, No) }
alias -l trivia.onoff { return $iif($trivia.on, On, Off) }
alias -l team.onoff { return $iif($team, On, Off) }
;########################################################
;# Init aliases.                                        #
;########################################################
alias -l nset { if ($getset($1, $2) == $null) { setset $1- } }
alias init.load {
  nset award 1 1 1 1 50 0  gives * a high five for getting ^ wins! Way to go * !
  nset award 2 1 1 1 100 0 gives * a large pizza for getting ^ wins! Way to go * !
  nset award 3 1 1 1 150 0 ^ wins... I am not worthy...
  nset award 4 2 1 1 3 0 hands * a cold beer for getting the last ^ questions!
  nset award 5 2 1 1 5 0 hands * 6-pack of icy beers for getting the last ^ questions!
  nset award 6 2 1 1 10 0 gives * keg of beer for kicking everybodies asses! ^ questions!
  nset award 7 2 1 1 15 0 bows before * a trivia god...
  nset award 8 2 2 2 3 5 You're on fire!
  nset award 9 3 4 5 1.5 0 Autoban based on speed.
  nset award 10 4 3 5 120 0 Autoban based on Words per minute.
  nset award 11 7 0 2 0 0 * has moved up in rank: ^
  nset award 12 8 0 2 0 0 *, congratulations on your promotion to: ^
}
alias trivia.init {
  nset status bot 1 | nset status echo 0 | nset status autohint 1 | nset status showanswer 1 | nset status cross 1
  nset status number 30 | nset status hintpause 1 | nset trivia additions additions.txt
  nset color 1 $fixer($rand(1,15)) | nset color 2 $fixer($rand(1,15)) | nset trivia default 10 | nset trivia dteam 5 | nset color on 1
  nset trivia delimiter * | nset trivia tnaoff 5 | nset trivia hintpause 5 | nset trivia perchint 30 | nset trivia numhint 1
  nset trivia ppq 1 | nset trivia dph 0 | nset lag answered 10 | nset lag hint 10 | nset lag start 15 | nset lag timed 15 | nset lag ping 10
  nset lag betweenhint 10 | nset lag timedout 60 | nset lag hintallow 10 | nset trivia dir $ifd($nofile($findfile($mircdir,$triv(questions), 1)),$mircdir)
  nset trivia report report.txt | nset trivia reset 1000 | nset team 0victory The *t1 and the *t2 tied | nset team 1 'Team 1's
  nset team 1victory The *t1 beat the *t2 | nset team 2 'Team 2's | nset team 2victory The *t2 beat the *t1 | nset team JoinBefore 2
  nset team JoinBeforeOn 1 | nset status nodecheater 1
  varcolors
}
alias -l trivia.fail {
  var %failedtriviafail = 0
  if ($version < 5.91) {
    echo Please use mIRC 5.91 or later.
    var %failedtriviafai = 1
  }
  if (!$server) {
    echo Please connect to a server before attempting to use $msg.trivia.version
    var %failedtriviafai = 1
  }
  if ($getset(status,bot) == 0) { 
    echo The trivia bot is off. Commands, Trivia, Disabled to reenable.
    var %failedtriviafai = 1
  }
  if ($isdir(" $+ $triv(dir) $+ ") == $false) { 
    echo The trivia directory, $triv(dir) $+ , is invalid.
    var %failedtriviafai = 1
  }
  if ($triv(dir) == $null) { 
    echo The trivia directory setting is blank, please set it to the desired directory.
    var %failedtriviafai = 1
  }
  if ($numl <= 0) {
    echo There appears to be no questions within the question file(s).
    var %failedtriviafai = 1
  }
  return %failedtriviafai
}
alias get.find { if ($qfind($1-)) return $qfind($1-) }
;########################################################
;# Trivia command, related aliases.                     #
;########################################################
alias -l ifd { return $iif($1, $1, $2) }
;########################################################
;# Command processing.                                  #
;########################################################
alias pre { return $ifd(%command-prefix, !) }
alias commandtokens { return state;disable;enable;op;trivia;strivia;pause;resume;theme;themes;stats;stat;won;hof;top10;hofstreak;row;streak;hoftime;hoffast;hofwpm;wpm;server;record;records;champ;version;web;add;report;ping;triviaping;help;join;showteams;roundscores;answer;next;hint;!hint;words;last;vowels;repeat;hofscoreday;hoftimeday;hofstreakday;hofwpmday;hofscoreweek;hoftimeweek;hofstreakweek;hofwpmweek;hofscoremonth;hoftimemonth;hofstreakmonth;hofwpmmonth;hofscoreyear;hoftimeyear;hofstreakyear;hofwpmyear;rank;promotion }
alias optokens { return enable;disable;ban;unban;banned;ask;add;find;team }
alias stattokens { return score;time;streak;wpm }
alias timetokens { return day;week;month;year;total }
alias starttokens { return Unlimited;team }
alias ctok { return $findtok($eval($ $+ $gettok(commandtokens;optokens;stattokens;timetokens;starttokens,$ifd($2,1),59),2),$untrans($1),1,59) }
alias gtok { return $trivtran($gettok($eval($ $+ $gettok(commandtokens;optokens;stattokens;timetokens;starttokens,$ifd($2,1),59),2),$1,59)) }
alias rtok { return $gettok($eval($ $+ $gettok(commandtokens;optokens;stattokens;timetokens;starttokens,$ifd($2,1),59),2),$1,59) }
alias -l processcommand {
  var %command = $right($1,$calc(-1 * $len($pre)))
  var %ctok = $ctok(%command)
  award command %command $2-

  if (!%ctok) { return }
  if (%ctok == 1) { inform $msg.trivia.state }
  if (%ctok == 2) { opcommand disable $2- }
  if (%ctok == 3) { opcommand enable $2- }
  if (%ctok == 4) { opcommand $2- }
  if (($getset(status,bot) == 0) || ($trivia.banned)) { return }
  if (%ctok == 5) { if (!$isdis(28)) { trivia $2- } }
  if (%ctok == 6) { if ((!$isdis(29)) && ($trivia.on) && ((!$team) || ($nick isop $iden))) { strivia $iden $nick } }
  if (%ctok == 8) { if (!$isdis(5)) { trivia.pause 1 } }
  if (%ctok == 7) { if ((!$trivia.paused) && (!$isdis(5))) { trivia.pause } }
  if (%ctok isnum 9-10) { if (!$isdis(18)) { inform $msg.trivia.themes } }
  if (%ctok isnum 11-13) { processcommand.stats $ifd($2,$nick) $ifd($3,$unit.default) }
  if (%ctok isnum 14-15) { if (!$isdis(8)) { processcommand.hof $ifd($2,score) $ifd($3,$unit.default) } }
  if (%ctok isnum 16-18) { if (!$isdis(10)) { processcommand.hof streak $unit.default } }
  if (%ctok isnum 19-20) { if (!$isdis(9)) { processcommand.hof time $unit.default } }
  if (%ctok isnum 21-22) { if (!$isdis(11)) { processcommand.hof wpm $unit.default } }
  if (%ctok isnum 45-60) {
    var %regmatch = / $+ (?: $+ $gtok(14) $+ $chr(124) $+ $rtok(14) $+ ) $+ \s?( $+ $gtok(1,3) $+ $chr(124) $+ $gtok(2,3) $+ $chr(124) $+ $gtok(3,3) $+ $chr(124) $+ $gtok(4,3) $+ $chr(124) $+ $rtok(1,3) $+ $chr(124) $+ $rtok(2,3) $+ $chr(124) $+ $rtok(3,3) $+ $chr(124) $+ $rtok(4,3) $+ )\s?( $+ $gtok(1,4) $+ $chr(124) $+ $gtok(2,4) $+ $chr(124) $+ $gtok(3,4) $+ $chr(124) $+ $gtok(4,4) $+ $chr(124) $+ $rtok(1,4) $+ $chr(124) $+ $rtok(2,4) $+ $chr(124) $+ $rtok(3,4) $+ $chr(124) $+ $rtok(4,4) $+ )/
    if ($regex(%command, %regmatch)) processcommand.hof $iif($regml(1),score) $ifd($regml(2),$unit.default)
  }
  if (%ctok isnum 61-62) { if (!$isdis(30)) inform $msg.trivia.rank($ifd($2,$nick)) }
  if (%ctok == 23) { inform $server }
  if (%ctok isnum 24-25) { if (!$isdis(12)) { inform $msg.trivia.records } }
  if (%ctok == 26) { inform $msg.trivia.champ }
  if (%ctok == 27) { inform $msg.trivia.version }
  if (%ctok == 28) { inform $msg.trivia.web }
  if (%ctok isnum 29-30) { if (!$isdis(19)) { trivia.report %ctok $2- } }
  if (%ctok isnum 31-32) { if (!$isdis(17))  { do.ping } }
  if (%ctok == 33) { if (!$isdis(32)) givehelp $2- }
  if (%ctok == 34) { if (($team) && (!$isdis(33))) { $setteam($nick, $2) } }
  if (%ctok == 35) { if ($team) { inform $msg.trivia.showteams } }
  if (%ctok == 36) { inform $msg.trivia.roundscores }
  if (%ctok == 37) { if (($thget(answer)) && (!$isdis(16))) { inform $msg.question.answer } }
  if ((!$question.on) || ($trivia.paused)) { return }
  if (%ctok == 38) { if (($calc($question.time * 2) >= $lag(timedout)) && (!$isdis(15))) { trivx $chan } }
  if (%ctok isnum 39-43) { 
    if (($question.time >= $lag(hintallow))) {
      if (($getset(trivia, hintpause)) && ($getset(status, hintpause))) { hadd -u $+ $triv(hintpause) Trivia $+ $idenn Temp. $+ hinted. $+ $nick 1 }
      if (%ctok isnum 39-40) { if (!$isdis(22)) { give.hint $iden } }
      if (%ctok == 41) { if (!$isdis(25)) { inform $msg.hint.words } }
      if (%ctok == 42) { if (!$isdis(24)) { inform $msg.hint.last } }
      if (%ctok == 43) { if (!$isdis(23)) { inform $msg.hint.vowels } }
    }
  }
  if (%ctok == 44) { if (!$isdis(26)) { inform $$thget(trivq.say) } }
}
alias processcommand.hof {
  if (!$2) { var %unit = 5 }
  else { var %unit = $ctok($2,4) }
  var %by = $ctok($1,3)
  if ($getset(hide,$rtok(%by,3))) { return }
  if ((!%by) || (!%unit)) { inform $msg.trivia.hof.error | return }
  inform $msg.trivia.topstats($rtok(%by,3),$rtok(%unit,4))
}
alias -l processcommand.stats {
  if (!$2) { var %unit = 5 }
  else { var %unit = $ctok($2,4) }
  if (!%unit) { inform $msg.trivia.stats.error | return }
  if ($1 isnum) { sort score $unit.set(%unit) }
  if ($1 isnum 1 - $hof.size) { inform $msg.trivia.stats($hof($1,1),$unit.set(%unit)) }
  else { inform $msg.trivia.stats($iif($1,$1,$nick),$unit.set(%unit)) }
}
alias unit.default { return $rtok($ifd($getset(status,scoreby),5),4) }
alias unit.set { return $iif($rtok($1,4) != total,$rtok($1,4)) }
alias unit.prefix { return $iif($ifd($1,$unit.default) != total, $ifd($1,$unit.default)) }
;########################################################
;# !Op command structure.                               #
;########################################################
alias -l opcommand {
  var %otok = $ctok($1,2)
  if ($isdis(6)) { return }
  if ((%otok == 1) && (!$isdis(21)) && ($getset(status,bot) == 0) && ((!$2) || ($2 == $me))) { 
    setset status bot 1
    tsay $msg.trivia.enabled
  }
  if ((%otok == 2) && (!$isdis(21)) && ($getset(status,bot) == 1)  && ((!$2) || ($2 == $me))) {
    setset status bot 0
    tsay $msg.trivia.disabled
    strivia $iden $nick
  }
  if ((%otok == 3) && (!$isdis(20))) {
    if (!$2) { inform $msg.trivia.error.ban }
    else {
      tban $2
      inform $msg.trivia.op.ban
    }
  }
  if ((%otok == 4) && (!$isdis(7))) {
    if (!$2) { inform $msg.trivia.error.unban }
    else {
      tunban $2
      inform $msg.trivia.op.unban
    }
  }
  if (%otok == 5) { inform $msg.trivia.banlist }
  if ((%otok == 6) && (!$isdis(14))) {
    if ($2 !isnum) { inform $msg.trivia.error.badnum }
    else {
      ask $2
      inform $msg.trivia.op.ask
    }
  }
  if ((%otok == 7) && (!$isdis(27))) {
    if (!$2) { inform $msg.trivia.error.noquestion }
    elseif ($triv(delimiter) !isin $2-) { inform $msg.trivia.error.nodelim }
    else {
      add $2-
      inform $msg.trivia.op.added
    }
  }
  if ((%otok == 8) && (!$isdis(13))) {
    if (!$2) { inform $msg.trivia.error.nosearch }
    else inform $msg.trivia.op.find($2-)
  }
  if ((%otok == 9) && (!$isdis(34))) {
    if ($2 ison $chan) {
      if ($validteam($3)) { $setteam($2, $3) }
      else { inform $msg.trivia.error.numberrequired($2) }
    }
    else { inform $msg.trivia.error.playerrequired }
  }
}
;########################################################
;# Trivia ON.                                           #
;########################################################
alias trivia {
  if (($trivia.banned) || ($trivia.on) || (!$trivchan)) { return }
  if ($trivia.paused) { 
    tsay $msg.trivia.pause
    return
  }
  trivia.flush
  if ($trivia.fail) return
  if ($hget(Trivia $+ $idenn)) { hfree Trivia $+ $idenn }
  hmake Trivia $+ $idenn 20
  if (($hget(Asked $+ $idenn)) && ($getset(status,keepask))) { hfree Asked $+ $idenn }
  if (!$hget(Asked $+ $idenn)) hmake Asked $+ $idenn 50
  trivia.defaultgame
  thset STime $time $date
  thset SUser $iif($nick,$nick,$me)
  if (($getset(Trivia,odefault) == unlimited) || (($ctok($1,5) == 1) && (!$isdis(2))) ) { thset Max Unlimited }
  if (($getset(Trivia,odefault) == team) || (($ctok($1,5) == 2) && (!$isdis(3)))) { thset team 1 }
  if (($1 isnum 1 - $numl) && (!$isdis(1))) { thset Max $int($1) }
  if ($1 == pi) { thset Max 3.14159265358979323846 }
  if ($1 == e) { thset Max 2.718281828459045 }
  if (!$isdis(18)) { trivia.themecheck $1- }
  if ($thget(team)) { trivia.teammode $2 }
  tsay $msg.trivia.started
  .timerq $+ $idenn 1 $ifd($lag(start),0) trivq $chan
  award roundstart $thget(Max)
}
;########################################################
;# Trivia OFF.                                          #
;########################################################
alias strivia {
  set -u3 %ident $1
  if ($team) { strivia.teammode }
  else if ($getset(status,bot)) {
    if ($getset(Var $+ $idenn, Lastwinner) == $2) { setset Var $+ $idenn Row 0 }
    tsay $msg.trivia.stopped
    if ($thget(Current) >= 10) { tsay $strivia.end($triv(Record)) }
    award RoundStop $thget(Current)
  }
  trivia.flush
}
alias strivia.end {
  if ($1 == 1) { return $msg.trivia.hof }
  elseif ($1 == 2) { return $msg.trivia.topstats(streak) }
  elseif ($1 == 3) { return $msg.trivia.topstats(time) }
  elseif ($1 == 4) { return $msg.trivia.topstats(wpm) }
  elseif ($1 == 5) { return $msg.trivia.champ }
  elseif ($1 == 6) { return $msg.trivia.web }
  elseif ($1 == 7) { return $msg.trivia.roundscores }
  return $msg.trivia.records
}
;########################################################
;# STATUS CLEARING.                                     #
;########################################################
alias -l trivia.flush {
  if (!$getset(status,keepask)) if ($hget(Asked $+ $idenn)) { hfree Asked $+ $idenn }
  if ($hget(Trivia $+ $idenn)) { hfree Trivia $+ $idenn }
  trivia.timersoff
  unset %cache.nick
  unset %cache.line
}
alias -l trivia.timersoff {
  .timer* $+ $idenn off
}
;########################################################
;# DEFAULT setup.                                       #
;########################################################
alias trivia.defaultgame {
  thset File questions.txt
  thset Scores $scoresfil
  if ($tchan($trivchan, 4)) { thset Scores $tchan($trivchan, 4) }
  if ($tchan($trivchan, 5)) {
    thset File
    var %i = 5
    while ($tchan($trivchan, %i)) {
      thset File $thget(file) $+ ; $+ $tchan($trivchan, %i)
      inc %i
    }
  }
  thset Max $triv(default)
  thset PPQ $iif($getset(Trivia,PPQ) != $null,$getset(Trivia,PPQ),1)
  thset DPH $iif($getset(Trivia,DPH) != $null,$getset(Trivia,DPH),0)
  thset RRS $iif($getset(Status,RRS) != $null,$getset(Status,RRS),0)
  thset guess $iif($getset(trivia,limitguess) != $null,$getset(trivia,limitguess),0)
  thset lagstart $iif($getset(lag, start) != $null, $getset(lag, start), 0)
  thset laganswered $iif($getset(lag, answered) != $null, $getset(lag, answered), 0)
  thset lagtimedout $iif($getset(lag, timedout) != $null, $getset(lag, timedout), 0)
  thset laghint $iif($getset(lag, hint) != $null, $getset(lag, hint), 0)
  thset lagtimed $iif($getset(lag, timed) != $null, $getset(lag, timed), 0)
  thset laghintallow $iif($getset(lag, hintallow) != $null, $getset(lag, hintallow), 0)
  thset lagbetweenhint $iif($getset(lag, betweenhint) != $null, $getset(lag, betweenhint), 0)
}
;########################################################
;# THEMED start.                                        #
;########################################################
alias trivia.themecheck {
  var %i = 1
  while ($getset(triviamode $+ %i, Name)) {
    if ($1 == $getset(triviamode $+ %i, Name)) {
      trivia.themestart %i
      if (($2 isnum) && ($2 <= $numq) && ($2 > 0) && (!$isdis(4))) { thset Max $int($2) }
      return
    }
    inc %i
  }
}
alias trivia.themestart {
  var %j = $setini(triviamode $+ $1,0)
  while (%j >= 1) {
    var %mode = $setini(triviamode $+ $1, %j)
    thset %mode $getset(triviamode $+ $1, %mode)
    dec %j
  }
}
;########################################################
;# TEAM setup.                                          #
;########################################################
alias -l trivia.teammode {
  thset Score1 0
  thset Score2 0
  thset Score3 0
  thset Score4 0
  if ($1 isnum 1 - $numq) { thset Max $int($1) }
  else { thset Max $triv(dteam) }
  tsay $msg.team.start
}
alias -l strivia.teammode {
  var %s1 = $thget(Score1)
  var %s2 = $thget(Score2)
  var %s3 = $thget(Score3)
  var %s4 = $thget(Score4)
  if ($getset(team,4-team)) {
    if ((%s1 > %s2) && (%s1 > %s3) && (%s1 > %s3)) {
      tsay $msg.team.over($te(1).victory)
      award TeamVictory 1
    }
    elseif ((%s2 > %s1) && (%s2 > %s3) && (%s2 > %s4)) {
      tsay $msg.team.over($te(2).victory)
      award TeamVictory 2 $get.showteams(2)
    }
    elseif ((%s3 > %s1) && (%s3 > %s2) && (%s3 > %s4)) {
      tsay $msg.team.over($te(3).victory)
      award TeamVictory 3
    }
    elseif ((%s4 > %s1) && (%s4 > %s2) && (%s4 > %s3)) {
      tsay $msg.team.over($te(4).victory)
      award TeamVictory 4 
    }
    else {
      tsay $msg.team.over($te(0).victory)
      award TeamVictory 0
    }
  }
  else {
    if (%s1 > %s2) { tsay $msg.team.over($te(1).victory) }
    elseif (%s1 < %s2) { tsay $msg.team.over($te(2).victory) }
    else { tsay $msg.team.over($te(0).victory) }
  }
  if ($getset(status, noshowt)) { tsay $msg.trivia.showteams }
}
alias -l setteam {
  if (($thget(Current) >= $getset(Team, JoinBefore)) && ($getset(Team, JoinBeforeOn) == 1)) { 
    inform $msg.team.joinover
    return
  }
  if ($validteam($2)) {
    if ($thget(Team. $+ $1) == $2) { inform $msg.team.alreadyon }
    else { tsay $msg.team.add($getset(team,$2), $1) }
    thset $eval(Team. $+ $1,1) $2
    setvar $1 team $2
  }
}
alias -l validteam {
  if ($1 isnum 1-2) return 1
  if (($1 isnum 3-4) && ($getset(team,4-team))) return 1
  return 0
}
alias -l setteam.hash {
  if ($validteam($2)) {
    thset $eval(Team. $+ $1,1) $2
  }
}
;########################################################
;# Trivia QUESTION.                                     #
;########################################################
alias trivq {
  set -u3 %ident $1
  if (!$hget(Trivia $+ $idenn)) { return }
  if ($trivia.fail) return
  thset Current $calc($thget(Current) + 1)
  if (($team) && ($thget(Current) == $getset(Team, JoinBefore)) && ($getset(Team, JoinBeforeOn) == 1)) { tsay $msg.team.joinbefore }
  create.question
  .timerend $+ $idenn 1 $lag(timedout) trivx $iden
  trivia.startautohint
  setset Var $+ $idenn Asked $calc($getset(Var $+ $idenn,Asked) + 1)
  thset Start $ticks
  trivia.sayquestion $right($thget(catq),-1)
  if ($getset(status,echo) == 1) { echo $iden $msg.trivia.echoanswer }
  if ($getset(status,answers)) { tsay $msg.hint.space }
  award Question $lag(timedout)
}
alias -l create.question {
  while ($thget(Ask1)) {
    var %qread = $qread($thget(Ask1))
    ask.deleteitem 1
    thset Catq
    if (%qread) return
  }
  var %temp.ask = $trivia.getq
  thset Catq $qcat(%temp.ask)
  hadd Asked $+ $idenn %temp.ask %temp.ask
}
alias -l trivia.getq {
  unset %ask
  while ((!%ask) || ($hget(Asked $+ $idenn, %ask))) {
    var %tempnumqvalue = $numq
    if (%tempnumqvalue == 0) {
      echo Attempted start without any questions to process. Bailing.
      halt
    }
    if ($hget(Asked $+ $idenn,0).item >= %tempnumqvalue) { hdel -w Asked $+ $idenn * }
    var %ask = $rand(1, %tempnumqvalue)
    if (!$qread(%ask)) { hadd Asked $+ $idenn %ask NA }
  }
  thset Asking %ask
  return %ask
}
;########################################################
;# QUESTION MISC.                                       #
;########################################################
alias qfile {
  if (($1 !isnum) || ($1 < 1)) return
  if (($thget(File)) && ($gettok($thget(File),$1,$asc(;)))) return $shortfn(" $+ $triv(dir) $+ \ $+ $gettok($thget(File),$1,$asc(;)) $+ ")
  if ($tchan($ifd($trivchan,1),$calc(4 + $1))) return $shortfn(" $+ $triv(dir) $+ \ $+ $tchan($ifd($trivchan,1),$calc(4 + $1)) $+ ")
}

alias numl { return $calc($numq - $numnonq) }
alias numq {
  if ($1 isnum) { return $lines($qfile($1)) }
  var %i = 0, %j = 1
  while ($qfile(%j)) {
    if (!$eval(% $+ numq $+ $qfile(%j),2)) { set -u600 % $+ numq $+ $qfile(%j) $lines($qfile(%j)) }
    %i = $calc(%i + $eval(% $+ numq $+ $qfile(%j),2))
    inc %j
  }
  return %i
}
alias qcat {
  if ($getset(status,nocat) == 1) return
  var %nf = $numfile($1)
  if ($exists($gettok(%nf,1,$asc(;)))) {
    return $read($gettok(%nf,1,$asc(;)), wnt, #*, $gettok(%nf,2,$asc(;)))
  }
}
alias numnonq {
  window -h @numnonq
  var %j = 1, %nonqcount = 0
  while ($qfile(%j)) {
    if ($eval(% $+ nonq $+ $qfile(%j),2)) { var %nonqcount = $calc(%numqcount + $eval(% $+ nonq $+ $qfile(%j),2)) }
    else {
      if ($exists($qfile(%j))) {
        filter -fwgx $qfile(%j) @numnonq /\ $+ $triv(delimiter) $+ /
        var %nonqcount = $calc(%nonqcount + $filtered)
        set -u600 % $+ nonq $+ $qfile(%j) $filtered
      }
    }
    inc %j
  }
  window -c @numnonq
  return %nonqcount
}
alias numcat {
  if ($window(@categories)) { window -c @categories }
  window -eh @categories
  var %j = 1
  while ($qfile(%j)) {
    if ($exists($qfile(%j))) filter -fw $qfile(%j) @categories #*
    inc %j
  }
  .timer 1 0 window -c @categories
  return $line(@categories,0)
}
alias numfile {
  var %i = 0, %j = 1, %l
  while ($qfile(%j)) {
    %l = %i
    inc %i $numq(%j)
    if ($1 isnum %l - %i) { return $qfile(%j) $+ ; $+ $calc($1 - %l) }
    if (($1 !isnum) && ($exists($qfile(%j))) && ($read($qfile(%j), nwt, $+(*,$1-,*), 1))) return $qfile(%j) $+ ; $+ $readn
    inc %j
  }
}
alias -l qfind {
  var %i = 0, %j = 1, %l
  if ($1 == $null) { return }
  while ($qfile(%j)) {
    if (($exists($qfile(%j))) && ($read($qfile(%j), nwt, $+(*,$1-,*), 1))) return $read($qfile(%j),$readn) - $qfile(%j) - $readn
    inc %j
  }
}
alias qread {
  var %nf = $numfile($1)
  var %delim = \ $+ $triv(delimiter)

  var %attemptread

  if ($1 isnum) {
    if ($exists($gettok(%nf,1,$asc(;)))) {
      var %attemptread = $read($gettok(%nf,1,$asc(;)), nt, $gettok(%nf,2,$asc(;))))
    }
  }
  else {
    var %attemptread $1-
  }  

  if (($regex(%attemptread,/^([^ $+ %delim $+ ]+)([ $+ %delim $+ ].*)$/))) {
    thset tok1 $regml(1)
    if ($regex($regml(2), /[ $+ %delim $+ ]([^ $+ %delim $+ ]+)/g)) {
      thset numfile %nf
      thset tokq $calc($regml(0) + 1)
      var %i = 1
      while (%i <= $regml(0)) {
        thset tok $+ $calc(%i + 1) $regml(%i)
        inc %i
      }
    }
  }
  else {
    if ($1 == scramble) { thset temp.bonus S }
    if ($1 == reverse) { thset temp.bonus R }
    if ($1 == shotgun) { thset temp.bonus G }
    return $false
  }
  return $true
}

alias -l ask.deleteitem {
  hdel Trivia $+ $idenn Ask $+ $$1
  var %i = $1
  while ($thget(Ask $+ $calc(%i + 1))) {
    thset Ask $+ %i $thget(Ask $+ $calc(%i + 1))
    inc %i
  }
  if ($thget(Ask $+ %i)) { hdel Trivia $+ $idenn Ask $+ %i }
}
alias -l trivia.startautohint { if ($getset(status,autohint) == 1) { .timerhint $+ $idenn 1 $lag(hint) trivia.autohint $iden } }
alias -l trivia.autohint {
  give.hint $1
  if ($triv(numhint) > 1) { .timerhint $+ $idenn $calc($triv(numhint) - 1) $lag(betweenhint) give.hint $1 }
}
alias decheater {
  if ($getset(status,nodecheater) == 1) return $1-
  var %t.rt = $1-, %i = $count($1-,$chr(32)), %t.ps
  while (%i > 0) {
    if ($rand(1,2) == 1) {
      %t.ps = $pos($1-,$chr(32),%i)
      %t.rt = $+($left(%t.rt, $calc(%t.ps - 1)), $chr(160),$right(%t.rt,$calc((%t.ps) * -1)))
    }
    dec %i
  }
  return %t.rt
}
;########################################################
;#  QUESTION over.                                      #
;########################################################
alias trivx {
  set -u3 %ident $1
  if (!$hget(Trivia $+ $idenn)) { return }
  if (!$2) {

    if (($getset(status,showanswer)) && (!$getset(status,shownone))) {
      if ($thget(temp.type) == K) {
        tsay $msg.answer.timeout.kaos
      }
      else if ($thget(temp.type) == T) {
        tsay $msg.answer.timeout.total
      }

      else if ($thget(temp.type) == W) {
        tsay $msg.answer.timeout.wpm
      }
      else if ($thget(temp.type) == P) {
        tsay $msg.answer.timeout.pick
      }
      else {
        tsay $msg.answer.timeout
      }
    }
    else { tsay $msg.answer.timeout2 }

    setset Var $+ $idenn Row 0
    thset Unanswered $calc($thget(Unanswered) + 1)
    award NoAnswer $trivq.answer
  }
  trivia.timersoff
  if ($window($total.win)) { window -c $total.win }
  thset Answer $trivq.answer
  thset caseexact 0
  if ($hget(Trivia $+ $idenn)) hdel -w Trivia $+ $idenn Temp.*
  if ($hget(Trivia $+ $idenn)) hdel -w Trivia $+ $idenn tok*
  if (($nick) && ($getvar($nick,score) >= $triv(reset)) && ($getset(status,champ) == 1)) { trivia.newchamp }
  if ((($team) && ($thget(Score $+ $isteam($nick)) > $calc($thget(Max)/2))) || (($getset(status,emptyoff)) && ($nick($iden,0) <= 1)) || (($getset(status, naoff) == 1) && ($thget(unanswered) >= $triv(naoff))) || (($thget(Max) != unlimited) && ($thget(Current) >= $thget(Max)))) {
    strivia $1
    if (($getset(status, emptyoff) == 1) && ($nick($iden,0) <= 1)) tsay $msg.trivia.emptyoff 
    if (($getset(status, naoff) == 1) && ($thget(Unanswered) >= $triv(naoff))) tsay $msg.trivia.unactive
    return
  }
  .timerq $+ $idenn 1 $iif($1, $lag(answered), $lag(timed)) trivq $iden
}
alias -l trivia.processscore {
  if ($getset(Var $+ $idenn, Lastwinner) == $nick) { setset Var $+ $idenn Row $calc($getset(Var $+ $idenn, Row) + $ifd($2,1)) }
  else { setset Var $+ $idenn Row $ifd($2,1) }
  setset Var $+ $idenn Wins $calc($getset(Var $+ $idenn,Wins) + $ifd($2,1))
  setset Var $+ $idenn Lastwinner $nick
  setvar $nick Lastwin $date
  thset WPM $calc(($len($1) * 60) / ($thget(Time) * 5))
  if (($thget(WPM) > $getvar($nick,wpm)) || (!$getvar($nick,wpm))) { setvar $nick wpm $thget(WPM) }
  if (($getset(Var $+ $idenn, Row) > $getvar($nick,streak)) || (!$getvar($nick,streak))) { setvar $nick Streak $getset(Var $+ $idenn, Row) }
  if (($thget(Time) < $getvar($nick,time)) || (!$getvar($nick,time))) { setvar $nick Time $thget(Time) }
  thset temp.cng $calc(($thget(PPQ) * $ifd($2,1)) - ($thget(DPH) * $max.hinted))
  if ($thget(temp.points) != $null) { thset temp.cng $calc(($thget(temp.points) - ($max.hinted * $thget(temp.hintreduction))) * $ifd($2,1)) }
  thset temp.mrank $getmrank($nick)
  thset temp.rank $getrank($nick,$unit.default,$thget(temp.cng))
  thset temp.newrank $calc($thget(temp.rank) - %uprank)
  setvar $nick Score $calc($getvar($nick, Score) + $thget(temp.cng))
  setvar $nick Answered $calc($getvar($nick, Answered) + $iif($2 > 0,$2,1))
  thset $eval(Score. $+ $nick,1) $calc($thget($eval(Score. $+ $nick,1)) + $thget(temp.cng))
  process.scores.time $nick $thget(temp.cng) $getset(Var $+ $idenn, Row) $thget(Time) $thget(WPM)
}
alias trivia.processawards {
  if (%uprank) award uprank $tranord($thget(temp.newrank))
  if ($getmrank($nick) != $thget(temp.mrank)) award promotion $getmrank($nick)
  award score $user.score($nick)
  award row $getset(Var $+ $idenn, Row)
  award time $thget(Time)
  award wpm $thget(WPM)
  award answered $thget(Time)
}

alias -l answered {
  thset Time $question.time
  if (($1 == $null) || ($trivia.banned) || ($trivia.negationcheck) || (($team) && (!$isteam($nick)))) { return }
  $trivia.processscore($1,$2) 
  if (($getset(build,instabuild)) && ($getset(build,instabuild) // $getset(Var $+ $idenn,Wins))) { htmltrigger $iden }
  tsay $msg.answer.correct($getset(status,tradwin),$thget(WPM),$thget(temp.newrank),$iif(%uprank,$thget(temp.rank)))
  if ($team) {
    thset Score $+ $isteam($nick) $calc($thget( Score $+ $isteam($nick)) + 1)
    tsay $msg.team.score
    award TeamAnswered $isteam($nick)
  }
  trivia.processawards
  if ($thget(RRS)) { tsay $msg.trivia.roundscores }
  hdel Trivia $+ $idenn Unanswered
  if (($isTotal) && ($total.over)) { tsay $msg.trivia.totalover }

  if ($thget(temp.type) == W) {
    return 
  }
  if ((($thget(temp.type) != T) && ($thget(temp.type) != K)) || ($total.over)) { trivx $chan $true }
}
alias -l trivq.answer { return $iif(((($thget(temp.type) == T) || ($thget(temp.type) == K) || ($getset(status,showmatched))) && ($thget(temp.matched))), $thget(temp.matched),$tok(2)) }
;########################################################
;# QUESTION Typing.                                     #
;########################################################
alias -l trivia.sayquestion {
  if ($right($tok(1),1) == $chr(61) ) {
    thset caseexact 1
    thset tok1 $left($tok(1),-1)
  }
  if ($regex($tok(1), /^([^:]+):\s?(.+)|((?i)Scramble|Uword|WPM|Type)$/)) {
    thset temp.mode $lower($regml(1))
    thset temp.rest $regml(2)
    if (($gettok($thget(temp.mode),1,44) isnum) && ($getset(status,nobonus) != 1)) {
      thset temp.points $gettok($thget(temp.mode),1,44)
      if ($gettok($thget(temp.mode),2,44) isnum) { thset temp.hintreduction $gettok($thget(temp.mode),2,44) }
      var %tq $msg.question.points($1-,$thget(temp.rest))
    }
    elseif ($regex($thget(temp.mode), /pick\s(\d+)/)) {
      var %tq $msg.question.standard($1-,$thget(temp.rest))
      thset temp.type P
      thset temp.pick $regml(1)
    }
    elseif (kaos == $thget(temp.mode)) {
      var %tq $msg.question.kaos($1-)
      thset temp.type K
      total.init
    }
    elseif (multi == $thget(temp.mode)) {
      var %tq $msg.question.multi($1-)
      thset temp.type M
    }
    elseif (WPM == $thget(temp.mode)) || (Type == $htget(temp.mode)) {
      var %tq $msg.question.wpm($1-,$thget(temp.rest))
      thset temp.type W
      thset caseexact 1
    }
    elseif (total == $thget(temp.mode)) { 
      var %tq $msg.question.total($1-)
      thset temp.type T
      total.init
    }
    elseif (scramble == $thget(temp.mode)) || (uword == $thget(temp.mode)) {
      var %tq $msg.question.scramble($1-,$thget(temp.rest))
      thset temp.type S
    }
  }
  if (!%tq) { var %tq $msg.question.standard($1-) }

  thset trivq.say $iif($getset(status,nosaycurrent) != 1, $e1($thget(Current)) $+ $e2(.)) $decheater(%tq)
  tsay $thget(trivq.say)
}
;########################################################
;# TOTAL question type, control.                        #
;########################################################
alias unfix {
  var %i = 2
  while (%i <= $tokq) {
    if ($1- == $fix($tok(%i))) { return $tok(%i) }
    inc %i
  }
}
alias total.win { return @total $+ $idenn }
alias total.init {
  var %i = 2
  if ($window($total.win)) { window -c $total.win }
  window -h $total.win
  while (%i <= $tokq) {
    aline -n $total.win $tok(%i)
    inc %i
  }
  thset temp.totalanswers $total.left
}
alias total.left { return $line($total.win,0) }
alias total.answers { return $thget(temp.totalanswers) }
alias total.answered { return $calc($total.answers - $total.left) }
alias total.is { return $fline($total.win,$1-,1) }
alias total.rem { dline $total.win $total.is($1-) }
alias total.over { return $iif(!$line($total.win,0), 1) }
alias isTotal { return $iif((($thget(temp.type) == T) || ($thget(temp.type) == K)),$true) }
alias gettotalhints {
  var %i = 1, %totalhint
  while (%i <= $line($total.win,0)) {
    %totalhint = $left(%totalhint,850) $+ $iif(%totalhint,$chr(44)) $plot($1,$line($total.win,%i))
    inc %i
  }
  return %totalhint
}
alias gettotalremain {
  var %i = 1, %totalremain
  while (%i <= $line($total.win,0)) {
    %totalremain = $left(%totalremain,850) $+ $iif(%totalremain != $null,$chr(44)) $line($total.win,%i)
    inc %i
  }
  return %totalremain
}
;########################################################
;# Trivia block answer.                                 #
;########################################################
alias -l trivia.negationcheck {
  if ($thuser(Hinted)) {
    inform $msg.trivia.hintpaused
    return $true
  }
  if ($thget(temp.type) != W) {
    if (($getset(status,limitguess)) && (!$isTotal) && ($ifd($thuser(Guess),0) >= $thget(guess))) {
      inform $msg.trivia.guessed($thuser(guess))
      return $true
    }
  }
  else if ($ifd($thuser(Guess),0) >= 2) {
    inform $msg.trivia.guessed.wpm
    return $true
  }
}
;########################################################
;# Guess processing.                                    #
;########################################################
alias -l processguess {
  if ($trivia.paused) { return }
  if (($team) && (!$isteam($nick))) {
    if ($validteam($getvar($nick,team))) {
      $setteam.hash($nick,$getvar($nick,team))
    }
  }
  var %pick = $regex($fix($1-), $trivia.pattern)
  thuset Guess $calc($thuser(guess) + 1)
  if (%pick == 0) { return }
  var %answered, %matched = $regml(1), %i = 1
  thset temp.match $regml(0)
  while ($thget(temp.match) >= %i) {
    thset temp.match. $+ %i $regml(%i)
    inc %i
  }
  if (($thget(temp.type) == P) || ($thget(temp.type) == T) || ($thget(temp.type) == W) || ($thget(temp.type) == K)) {
    var %j = 1, %k, %f, %numb.correct = 0
    while (%j <= $thget(temp.match)) {
      var %k = %j, %f = $true
      while (%k >= 1) {
        if ((%j != %k) && ($thget(temp.match. $+ %j) == $thget(temp.match. $+ %k))) { %f = $false }
        dec %k
      }
      if ($isTotal) {
        if ($total.is($unfix($thget(temp.match. $+ %j)))) {
          total.rem $unfix($thget(temp.match. $+ %j))
          inc %numb.correct
        }
        else { %f = $false }
      }
      if (%f) %answered = %answered $unfix($thget(temp.match. $+ %j))
      else { dec %pick }
      inc %j
    }
    if (($thget(temp.type) == P) && (%pick < $thget(temp.pick))) return
    if (($isTotal) && (%numb.correct == 0)) return
  }
  else { var %answered = $unfix($thget(temp.match. $+ 1)) }
  thset temp.matched %answered
  $answered(%answered,%numb.correct)
}
alias fix {
  if ($thget(caseexact)) return $1-
  if ($getset(status,nospellfix)) { return $lower($strip($1-)) }
  var %temp.fix = $lower($strip($1-))
  .echo -q $regsub(%temp.fix,/([^\s]+)s(?=(\s|$))/g, \1, %temp.fix)
  .echo -q $regsub(%temp.fix,/(?<=^|\s)(?:the|an|a)\s([^\s]+)/g, \1, %temp.fix)
  %temp.fix = $remove(%temp.fix,',-,!,`,.,,´,?,%,$chr(36),$chr(44))
  %temp.fix = $replace(%temp.fix,À,A,Á,A,Â,A,Ã,A,Ä,A,Å,A,Æ,AE,Ç,C,È,E,É,E,Ê,E,Ë,E,Ì,I,Í,I,Î,I,Ï,I,Ð,D,Ñ,N,Ò,O,Ó,O,Ô,O,Õ,O,Ö,O,Ø,O,Ù,U,Ú,U,Û,U,Ü,U,Ý,Y)
  %temp.fix = $replace(%temp.fix,ß,B,à,a,á,a,â,a,ã,a,ä,a,å,a,æ,ae,ç,c,è,e,é,e,ê,e,ë,e,ì,i,í,i,î,i,ï,i,ð,o,ñ,n,ò,o,ó,o,ô,o,õ,o,ö,o,ù,u,ú,u,û,u,ü,u,ý,y,ÿ,y)
  return $replace(%temp.fix,kn,n,y,i,k,c,x,c,q,c,e,a,ah,a,u,o,ph,f,m,n,ll,l,aa,a,oo,o,cc,c,z,s)
}

alias trivia.pattern {
  if ($thget(temp.pattern)) { return $thget(temp.pattern) }
  var %i 2, %max = $iif($thget(temp.type) == M, 2, $tokq), %pattern = $chr(40)
  while (%i <= %max) {
    if (%i != 2) { %pattern = %pattern $+ $chr(124) }
    %pattern = %pattern $+ $fix($tok(%i))
    inc %i
  }
  %pattern = %pattern $+ $chr(41)
  if (($thget(temp.type) != P) && ($thget(temp.type) != T) && ($thget(temp.type) != K)) {
    if ($getset(status, exactmatch)) { %pattern = ^ $+ %pattern $+ $ }
    elseif ($getset(status, nomid)) { %pattern = ^ $+ %pattern $+ (?=\s|$) $+ $chr(124) $+ (?:^|\s) $+ %pattern $+ $ }
    else { %pattern = (?:^|\s) $+ %pattern $+ (?=\s|$) }
  }
  else { %pattern = (?:^|\s) $+ %pattern $+ (?=\s|$) }
  %pattern = / $+ %pattern $+ /g
  thset temp.pattern %pattern
  return %pattern
}

;########################################################
;# PAUSE/RESUME processing.                             #
;########################################################
alias trivia.paused { if (($thget(paused)) && ($hget(Trivia $+ $idenn))) { return $true } }
alias trivia.pause {
  if ($1) {
    if ($trivia.paused) {
      .timerq $+ $idenn -r
      .timerend $+ $idenn -r
      .timerhint $+ $idenn -r
      thset paused 0
      tsay $msg.trivia.resume
    }
    else if (($thget(paused) != 1) && (!$timer(q $+ $idenn)) && (!$timer(end $+ $idenn)) && (!$timer(hint $+ $idenn)) && ($hget(Trivia $+ $idenn))) trivx
  }
  else {
    .timerq $+ $idenn -p
    .timerend $+ $idenn -p
    .timerhint $+ $idenn -p
    thset paused 1
    tsay $msg.trivia.pause
  }
}
;########################################################
;# Hint setup.                                          #
;########################################################
alias -l give.hint {
  set -u3 %ident $1
  if ((!$hget(Trivia $+ $idenn)) || ($max.hinted >= $triv(numhint))) { return }
  if ($thget(temp.type) == W) return
  if (!$nick) {
    thset Temp.Hints $calc($thget(Temp.Hints) + 1)
    var %hintpercent = $calc($triv(perchint) * $thget(Temp.Hints))
    var %nexthintpercent = $calc($triv(perchint) * ($thget(Temp.Hints) + 1))
    if ($thget(Temp.Skip.Hint $+ $thget(Temp.Hints)) == 1) { return }
    if ($hintrepnum(%hintpercent) == $hintrepnum(%nexthintpercent)) thset Temp.Skip.Hint $+ $calc($thget(Temp.Hints) + 1) 1
    if ($thget(Temp.Hints) == 1) tsay $eval($ $+ msg.hint. $+ $hintfirst $+ ( %hintpercent ),2)
    else tsay $msg.hint.hint(%hintpercent)

  }
  else {
    thuset Hint $calc($iif($calc($thget(Temp.Hints) + 0) > $calc($thuser(hint) + 0),$thget(Temp.Hints),$thuser(hint)) + 1)
    if ($thget(Temp.Skip.Hint $+ $thuser(hint)) == 1) { return }
    var %sayhint = $msg.hint.hint($calc($triv(perchint) * $thuser(hint)))
    if (msg * iswm %respond) {
      tsay %sayhint
      thset Temp.Skip.Hint $+ $thuser(hint) 1
    }
    else inform %sayhint
  }
  award Hint $thget(Temp.Hints)
}
alias -l hintfirst {
  var %hintfirst = $getset(trivia, firsthint)
  if (!%hintfirst) return hint
  if (%hintfirst == 1) return last
  if (%hintfirst == 2) return vowels
  if (%hintfirst == 3) return $gettok(hint.last.vowels.space.scramble, $rand(1,5), $asc(.))
}
alias -l get.hint {
  if ($thget(Temp.type) == M) { return }
  if (($thget(temp.rhint. $+ $2)) && ($1 == hint)) { return $thget(temp.rhint. $+ $2) }
  var %perhint = $iif($2,$2,$triv(perchint)), %hintc

  if ($isTotal) {
    thset temp.rhint. $+ $2 $gettotalhints(%perhint)
    return $thget(temp.rhint. $+ $2)
  }
  if ($1 == words) { return $numtok($trivq.answer,32) }
  if ($1 == space) { return $deletter($trivq.answer) }
  if ($1 == last) { return $right($trivq.answer,1) }
  if ($1 == vowels) { return $iif($regsub($trivq.answer, /([^aeiouAEIOU\s])/g, $trivchar, %hintc), %hintc, $trivq.answer) }
  if ($1 == scramble) { return $scramble($trivq.answer) }
  if ($getset(status, plot)) { return $plot(%perhint, $trivq.answer) }
  if ($getset(status, scatter)) {
    thset temp.rhint. $+ $2 $scatter(%perhint, $trivq.answer)
    return $thget(temp.rhint. $+ $2)
  }
  else { return $standard(%perhint, $trivq.answer) }
}
alias -l trivchar { return $iif($chr($triv(ch)),$chr($triv(ch)),_) }
alias -l nonpunct { return /([^';:"\s\xA0\,\?\<\>\|\\\/\[\]\!\@\#\$\%\^\&\*\(\)\{\}\-])/g }
alias -l deletter {
  var %hintc
  .echo -q $regsub($1-, $nonpunct, $trivchar, %hintc)
  return %hintc
}
alias -l hintrepnum { return $int($calc(($len($trivq.answer) / 100) * $1 + 1)) }
alias -l standard {
  var %in = $replace($2-, $chr(32), $chr(160)), %break = $hintrepnum($1)
  return $replace($left(%in, %break) $+ $iif($getset(status,cross) == 1, $deletter($right(%in, $calc(-1 * %break)))), $chr(160), $chr(32))
}
alias -l scramble {
  tokenize 32 $1-
  var %i = 1, %temp.smbl
  while (%i <= $0) {
    var %word = $eval($+($,%i),2)
    while (%word != $null) { var %rand = $rand(1, $len(%word)), %temp.smbl = %temp.smbl $+ $mid(%word, %rand, 1), %word = $left(%word, $calc(%rand - 1)) $+ $right(%word, $calc(-1 * %rand)) }
    %temp.smbl = %temp.smbl $+ ;
    inc %i
  }
  return $lower($replace(%temp.smbl,;,$chr(32)))
}
alias -l reverse {
  var %i = $len($1-),%reversed, %space
  while (%i >= 1) {
    if (!%space) { %reversed = %reversed $+ $mid($replace($1-,$chr(32),$chr(160)),%i,1) }
    %space = $false
    if ($chr($mid($1-,%i,1)) == 32) { %space = $true }
    dec %i
  }
  return $replace(%reversed,$chr(160),$chr(32))
}

alias scatter {
  var %hintc = $2-
  if ($thget(temp.scattermask)) var %schint = $thget(temp.scattermask)
  else {
    var %schint
    !.echo -q $regsub(%hintc,$nonpunct,@,%schint)
  }
  var %rnum = $int($calc(($regex(%schint,/@/g) / 100) * (100 - $1)))
  while (%rnum >= 0) {
    if ($regex(%schint,/(@)/g)) !.echo -q $regsub(%hintc,/(?<=^.{ $+ $calc($regml($rand(1,$regml(0))).pos - 1) $+ })./,@, %hintc)
    dec %rnum
  }
  thset temp.scattermask %hintc
  return $replace(%hintc,@,$trivchar)
}

alias plot {
  if ($1 >= 100) { return $2- }
  var %hintc, %i = 1, %j = 0, %rnum = $int($calc(($regsub($2-,$nonpunct,@,%hintc) / 100) * $1))
  while (%i <= %rnum) {
    if ($regex(%hintc, /(?:^|\s|\xA0)[^\s\xA0@]{ $+ %j $+ }(@)/g) == 1) { inc %j }
    %hintc = $+($left(%hintc,$calc($regml(1).pos - 1)), $mid($2-,$regml(1).pos,1),$right(%hintc,$calc($regml(1).pos * -1)))
    inc %i
  }
  return $replace(%hintc,@,$trivchar)
}
alias startandrandom {
  if ($1 > 0) return $replace($hget(hints,$1),@,$trivchar)
  if ($hget(hints)) hfree hints
  var %hintc = $2-, %onhint = 10, %f
  while (%hintc) {
    var %w = $gettok(%hintc,1,32), %rt = $regsub(%w,$nonpunct,@,%f), %hintc = $gettok(%hintc,2-,32), %k = 1
    while (%k <= %onhint) {
      hadd -m hints %k $hget(hints,%k) %f
      if ($regex(%w,$nonpunct) > 1) !.echo -q $regsub(%w, /(?<=^.{ $+ $iif(%k == 1, 0, $calc($regml($rand(1,$regml(0))).pos - 1)) $+ })(.)/,@, %w) $regsub(%f, /(?<=^.{ $+ $calc($regml(1).pos - 1) $+ })./,$regml(1), %f)
      inc %k
    }
  }
}

;########################################################
;# CHAMP aliases.                                       #
;########################################################
alias -l trivia.newchamp {
  .rename $scoresfil $asctime(yymmddhhmmss) $+ .bak
  setset Champ $calc($setini(Champ, 0) + 1) $nick
  tsay $msg.trivia.victory($nick)
  award Champ $nick
  trivia.flush
  haltdef
}
;########################################################
;# HALL Of FAME, RANKING.                               #
;########################################################
alias sort {
  if (!$exists($scoresfil)) { return }
  window -h $twin
  filter -fwcgut $+ $iif($1 != time,e) [ $$gttok($iif($2 != total,$2) $+ $1) $asc(;) ] $scoresfil $twin $iif(($2) && ($2 != total),/^ $+ $str([^;]*;,$calc($$gttok($2)-1)) $+ $eval($ $+ get. $+ $2,2) $+ ;.* $+ /,/.*/)
}
alias -l msg.trivia.topx {
  if ($calc($3 - $2) > 20) { return $msg.trivia.error.topx }
  sort $1 $unit.default
  var %temp.by = $gttok($1), %i = $2, %temp.ten = $e2(Places) $e1($2) $e2(to) $e1($3) $+ $e2(:)
  while (%i <= $3) {
    var %temp.ten = %temp.ten $e1($iif($hof(%i,1),$hof(%i,1) - $hof(%i,%temp.by)) $+ $e2(;)
    inc %i
  }
  return %temp.ten
}
alias -l msg.trivia.topstats {
  sort $1 $iif($2 != total, $2)
  var %temp.by = $gttok($iif($2 != total, $2) $+ $1), %temp.ten = $e1($hof(1,1)) $e2(has the best $1 of) $e1($hof(1,%temp.by)) $iif($2 != total,$e2( for the $2 )) $+ $e2(;)
  var %i = 2
  while (%i <= $iif(%topnum,%topnum,10)) {
    var %temp.ten = %temp.ten $iif($hof(%i,1),$e1($hof(%i,1)) $e2(-) $e1($hof(%i,%temp.by)) $+ $e2(;))
    inc %i
  }
  return $iif(!$hof(1,1),$e2(No elements in the hall of fame.),%temp.ten)
}
alias topnum { set %topnum $1 }
alias -l twin { return @trivia $+ $scoresfil }
alias -l getrank {
  sort score $iif($2 != total, $2)
  set -u0 %getrank $fline($twin,$+($1,;*),1)
  if (!%getrank) { return $hof.size }
  var %score = $getvar($hof(%getrank,1),$iif($2 != total, $2) $+ score)
  while (%score == $getvar($hof(%getrank,1),$iif($2 != total, $2) $+ score)) { dec %getrank }
  inc %getrank
  if (%getrank != 1) {
    set -u0 %getnextrank $calc(%getrank - 1)
    set -u0 %getnextrankuser $hof(%getnextrank,1)
    set -u0 %getnextrankat $user.score(%getnextrankuser,$2)
  }
  unset %uprank
  if (!$3) { return %getrank }
  set -u0 %uprank 1
  var %upscore = $calc(%score + $3)
  while ((%upscore >= $getvar($hof($calc(%getrank - %uprank),1),$iif($2 != total, $2) $+ score)) && (%getrank >= %uprank)) {
    inc %uprank
  }
  dec %uprank
  return %getrank
}
alias mrankon {
  if (!$getset(trivia, ranks)) { return $false }
  if ($setini(ranks,0) == 0) { return $false }
  else { return $true }
}
alias getmrank {
  if (!$getset(trivia, ranks)) { return }
  var %score = $user.score($1,$2), %i = $setini(ranks,0), %te = 0, %temax = 0
  while (%i >= 1) {
    %te = $setini(ranks,%i)
    if ((%score >= %te) && (%te >= %temax)) { %temax = %te }
    dec %i
  }
  return $getset(ranks,%temax)
}
alias getnextmrank {
  var %next.rank = $getnextmrankat($1)
  return $iif(%next.rank, $getset(ranks,%next.rank), None)
}
alias getnextmrankat {
  if (!$getset(trivia, ranks)) { return }
  var %score = $1, %i = $setini(ranks,0), %te = 0, %temax = 0, %by = 0
  while (%i >= 1) {
    %te = $setini(ranks,%i)
    if ((%score <= %te) && ((!%by) || ($calc(%score + %by) >= %te))) {
      %temax = %te
      %by = $calc(%te - %score)
    }
    dec %i
  }
  return %temax
}

alias -l recordstat {
  sort $1 $unit.default
  return $hof(1,1)
}
;########################################################
;# TIME SCORE DURATIONS AND GENERAL ALIASES             #
;# All time alias just return the number of that time   #
;# unit which have occurred since Jan 1st, 1970         #
;# Do not alter the unit.tokens. It will break the bot. #
;########################################################
alias unit.tokens { return year.month.week.day }
alias get.day { return $int($calc(($ctime - $timezone) / 86400)) }
alias get.week { return $int($calc((($get.day - 4) - $iif($getset(status,monday),0,1)) / 7)) }
alias get.month { return $calc(($get.year * 12) + $asctime($ctime,mm)) }
alias get.year { return $calc($asctime($ctime,yyyy)  - 1970) }
alias process.scores.time {
  var %i = 1
  while (%i <= 4) {
    var %unit = $gettok($unit.tokens,%i,$asc(.))
    var %uvalue = $eval($ $+ get. $+ %unit,2)
    if ((%unit) && (%uvalue)) {
      if ($getvar($1,%unit) != %uvalue) {
        setvar $1 %unit %uvalue
        setvar $1 %unit $+ score $calc(0 + $2)
        setvar $1 %unit $+ streak $calc(0 + $3)
        setvar $1 %unit $+ time $ifd($4,9999)
        setvar $1 %unit $+ wpm $calc(0 + $5)
      }
      else {
        if ($2) setvar $1 %unit $+ score $calc($getvar($1,%unit $+ score) + $2)
        if ($3 > $getvar($1,%unit $+ streak)) setvar $1 %unit $+ streak $3
        if ($4 < $getvar($1,%unit $+ time)) setvar $1 %unit $+ time $4
        if ($5 > $getvar($1,%unit $+ wpm)) setvar $1 %unit $+ wpm $5
      }
    }
    inc %i
  }
}
;########################################################
;# VAR MANIPULATIONS.                                   #
;########################################################
alias setvar {
  if ($3 == $null) return
  if ($exists($tempfil)) var %backburner = $read($tempfil, wnt, $1 $+ ;*)
  if (%backburner != $null) mergeentry $tempfil $scoresfil $1
  var %newline = $readvar($1)
  if (!%newline) { %newline = $1 }
  if ($numtok(%newline,59) < $numtok($tvartoks, $asc(.))) {
    %newline = %newline $+ $str(;0,$calc($numtok($tvartoks, $asc(.)) - $numtok(%newline,59)))
    if ($gettok(%newline,9,59) == 0) { %newline = $puttok(%newline,trivia,9,59) }
    if (($gettok(%newline,8,59) == 0) && ($address($1,5))) { %newline = $puttok(%newline,$address($1,5),8,59) }
    if ($gettok(%newline,6,59) == 0) { %newline = $puttok(%newline,$date,6,59) }
    if ($gettok(%newline,3,59) == 0) { %newline = $puttok(%newline,9999,3,59) }
  }
  %newline = $puttok(%newline,$3-,$gttok($2),59)
  write $iif($readn,-l $+ $readn) $scoresfil %newline
  set -u3 %cache.nick $1
  set -u3 %cache.line %newline
}
alias readvar {
  if ($exists($scoresfil)) var %scoreline = $read($scoresfil, wnt, $1 $+ ;*)
  if (!%scoreline) { return }
  if (!$2) { return %scoreline }
  else { return $gettok(%scoreline, $gttok($2), 59) }
}
alias getvar {
  if ($1 == %cache.nick) { var %scoreline = %cache.line }
  else {
    var %scoreline = $readvar($1)
    if (!%scoreline) { return }
    set -u3 %cache.nick $1
    set -u3 %cache.line %scoreline
  }
  if (!$2) { return %scoreline }
  else { return $gettok(%scoreline, $gttok($2), 59) }
}
alias -l gttok { return $findtok($tvartoks, $1, 1, $asc(.)) }
alias -l tvartoks { return name.score.time.streak.wpm.lastwin.answered.address.team.admin.block.day.dayscore.daystreak.daytime.daywpm.week.weekscore.weekstreak.weektime.weekwpm.month.monthscore.monthstreak.monthtime.monthwpm.year.yearscore.yearstreak.yeartime.yearwpm }
alias -l varfil { return $iif($2 == $null, $iif($1 == 0, $lines($scoresfil), $gettok($read($scoresfil, $1),1,59)), $gettok($read($scoresfil, $1),$2,59)) }
alias trivini { return $iif($exists(trivia.ini),trivia.ini,$iif($exists(" $+ $scriptdir $+ \ $+ trivia.ini $+ ")," $+ $scriptdir $+ \ $+ trivia.ini $+ ",trivia.ini)) }
alias -l setset {
  if ($3- != $null) { writeini -n $trivini $1 $2 $3- }
  else { remini -n $trivini $$1 $2 }
}
alias getset { return $readini($trivini, n, $1, $2) }
alias -l setini { return $iif($2 != $null, $ini($trivini, $1, $2), $ini($trivini, $1)) }
alias -l thuser { return $thget($eval(Temp. $+ $1 $+ . $+ $nick,1)) }
alias -l thuset { thset $eval(Temp. $+ $1 $+ . $+ $nick,1) $2- }
alias -l thset { if ($hget(Trivia $+ $idenn)) hadd Trivia $+ $idenn $1- }
alias thget { return $hget(Trivia $+ $idenn, $1) }
;########################################################
;# Color aliases.                                       #
;########################################################
alias -l colorcode { return $gettok(colors off.white.black.blue.green.lightred.brown.purple.orange.yellow.lightgreen.cyan.lightcyan.lightblue.pink.grey.lightgrey,$calc($1 + 1),$asc(.)) }
alias -l fixer { return $base($1,10,10,2) }
alias varcolors {
  unset %c1 %c1o %c2 %c2o
  if ((!$getset(color,on)) || (!$tc(1)) || (!$tc(2))) { return }
  %c1o = $iif($tc(1).b,$chr(2)) $+ $iif($tc(1).u,$chr(31)) $+ $chr(3)
  %c2o = $iif($tc(2).b,$chr(2)) $+ $iif($tc(2).u,$chr(31)) $+ $chr(3)
  %c1 = %c1o $+ $fixer($calc($tc(1) - 1)) $+ $iif(($tc(3)) && ($getset(color,bon)), $chr(44) $+ $fixer($calc($tc(3) - 1)))
  %c2 = %c2o $+ $fixer($calc($tc(2) - 1)) $+ $iif(($tc(4)) && ($getset(color,bon)), $chr(44) $+ $fixer($calc($tc(4) - 1)))
}
alias rdc {
  if ($getset(status,nocolorshort) == 1) return $1
  var %a
  !.echo -q $regsub($1,/(?<=\x03|\x03\d\d\x2C)(\d)(?!\d)/g,0\1, %a)
  while ($regsub(%a, /(?<=\x03\d\d\x2C\d\d|\x03\d\d\x03|\x03)([\x02\x1F\x16\s\xA0]+)(\x03(?:\d\d(?:\x2C\d\d)?)?)/g,\2\1, %a)) { }
  !.echo -q $regsub(%a, /(\x02)([\x1F\x16\s\xA0]*)\1/g,\2, %a) $&
    $regsub(%a, /(\x1F)([\x02\x16\s\xA0]*)\1/g,\2, %a) $&
    $regsub(%a, /(\x16)([\x02\x1F\s\xA0]*)\1/g,\2, %a) $&
    $regsub(%a, /(?:\x03(?:\d\d(?:\x2C\d\d)?)?)+(\x03(?:(?!\d)|\d\d\x2C\d\d))/g,\1, %a) $&
    $regsub(%a, /(?:\x03\d\d)(\x2C\d\d)(?:\x03\d\d)*(\x03\d\d)/g,\2\1, %a) $&
    $regsub(%a, /(?<=\x03\d\d)(\x2C\d\d)([^\x03]+\x03\d\d)\1/g,\1\2, %a)
  while ($regsub(%a,/(\x03\d\d)((\x2C\d\d)?[^\x03]+)\1(?!\x2c\d)/g,\1\2, %a)) { }
  !.echo -q $regsub(%a, /^\x03(?!\d)|(\x03(\d\d(\x2C\d\d)?)?|\x02|\x16|\x1F)+$/g,,%a) $&
    $regsub(%a, /(?<=\x03|\x03\d\d\x2C)0(\d)(?!\d)/g,\1, %a)
  return %a
}
;########################################################
;# AWARD setups.                                        #
;########################################################
alias -l msg.trivia.award { raw -q privmsg $iden $nick : %c2 $+ $replace($eval($1,2),^, %c2o $+ $e1($2) $+ %c2,*, %c2o $+ $e1($replace($nick,>,Guest_)) $+ %c2) $+ %c2o }
alias -l award {
  if ($getset(status,noawards)) { return }
  var %i = 1, %award = $calc($findtok($award.on.tok, $1, 1, $asc(.)) - 1), %trigger = $2-
  while ($aw(%i)) {
    tokenize 32 $aw(%i)
    if (%award == $1) {
      if (($2 == 0) || (($2 == 1) && (%trigger == $4)) || (($2 == 2) && (%trigger isnum $4 - $5)) || (($2 == 3) && (%trigger >= $4)) || (($2 == 4) && (%trigger <= $4)) || (($2 == 5) && (%trigger == $getrank($nick,$unit.default))) || (($2 == 6) && ($rand(1,$4) <= $5)) || (($2 == 7) && ($4 $+ * iswm %trigger)) || (($2 == 8) && (* $+ $4 iswm %trigger))) { $award.act($3,%trigger,$6-) }
    }
    inc %i
  }
}
alias award.act {
  var %do
  if ($1 == 1) { var %do = inform $msg.trivia.award($3,$2) }
  if (($1 == 2) || ($1 == 5)) { var %do = tsay $msg.trivia.award($3,$2) }
  if ($1 == 3) { var %do = .notice $msg.trivia.award($3,$2) }
  if ($1 == 4) { var %do = trivia.credit $nick $3 }
  if ($1 == 5) { var %do = tban $nick }
  if ($1 == 6) { var %do = $eval($replace($3-,*,$2),3) }
  .timer 1 0 schan $chan %do
}
alias schan {
  set -u10 %ident $1
  $2-
}
alias award.on.tok { return Null.Score.Row.Time.WPM.Join.Question.Uprank.Promotion.Answered.RoundStart.RoundStop.Command.NoAnswer.Hint.HTMLUpdate.Champ.TeamVictory.TeamAnswered }
alias award.val.tok { return Always.Exactly.Between.At Least.At Most.Ranked.Random.Begins.Ends }
alias award.do.tok { return Null.Describe.Msg.Notice.Give Points.Ban.Special }
;########################################################
;# MESSAGING.                                           #
;########################################################
alias -l inform {
  if ((!$1) || (!$server)) { return }
  if (!%respond) {
    var %respondlevel = $getset(status,respondlevel)
    set -u2 %respond raw -q privmsg $iden $nick : 
    if (%respondlevel == 2) { }
    if (%respondlevel == 3) { set -u2 %respond msg $iden }
    if (%respondlevel == 4) { set -u2 %respond msg $nick }
    if (%respondlevel == 5) { set -u2 %respond describe $iden }
  }
  $iif($scid(%cid.force),scid %cid.force) $iif($nick == $me, .timer -m 1 $calc($timer(0) * 100)) %respond $1- 
}
alias here { set %cid.force $cid }
alias -l tsay { if (($1) && ($server) && ($me ison $iden)) { $iif($nick == $me, .timer -m 1 $calc($timer(0) * 100)) msg $iden $1- } }
alias -l tact { if (($1) && ($server) && ($me ison $iden)) msg $iden $1- }
;########################################################
;# Direct basic processing, for special functions.      #
;########################################################
alias -l do.ping {
  if ($eval(% $+ pingantispam. $+ $nick,2)) return
  ctcp $nick ping
  set -u120 % $+ ping. $+ $nick $ticks
  set -u120 % $+ pingchan. $+ $nick $chan
  set -u120 % $+ pingcid. $+ $nick $cid
}
alias -l trivia.report {
  inform $msg.trivia.thanks
  write " $+ $triv(dir) $+ / $+ $iif($1 == 29, $triv(additions), $triv(report)) $+ " $nick $adate $time $2-
}
;########################################################
;# FRIENDS/BANNED.                                      #
;########################################################
alias addressize {
  if (*!*@* iswm $1) { return $1 }
  return $1 $+ !*@*
}
alias -l is.friend {
  var %i = 1
  while ($getset(friend, %i)) {
    if ($addressize($getset(friend, %i)) iswm $address($ifd($1,$nick),5)) { return %i }
    inc %i
  }
}
alias -l is.banned {
  var %i = 1
  while ($getset(banned,%i)) {
    if ($addressize($getset(banned, %i)) iswm $address($ifd($1,$nick),5)) { return %i }
    inc %i
  }
}
alias -l trivia.banned {
  var %banned = $is.banned($1)
  if (%banned) {
    if (!$1) { inform $msg.trivia.banned }
    return %banned
  }
}
alias -l ban.size { return $calc(1 + $setini(banned, 0)) }
alias -l tban { if (!$trivia.banned($$1)) { setset banned $ban.size $1 } }
alias -l tunban {
  var %i = $trivia.banned($$1)
  while ($getset(banned, $calc(%i + 1))) {
    setset banned %i $getset(banned, $calc(%i + 1))
    inc %i
  }
  setset banned %i
}
;########################################################
;# MISC.                                                #
;########################################################
alias timealias {
  var %ticks = $ticks
  echo -a ... $eval($ $+ $1,2) ... $calc(($ticks - %ticks) / 1000) ... $1
}
alias timealias2 {
  var %ticks = $ticks, %i = 1, %result
  while (%i <= $2) {
    var %result = $eval($ $+ $eval($1-,2),2)
    inc %i
  }
  return $calc(($ticks - %ticks) / (1000 * $2))
}
alias iden { return $iif($chan, $chan, $iif(%ident, %ident, $tchan(1))) }
alias idenn { return $iden $+ . $+ $ifd($network,irc) }
alias -l deleteplayer { if ($getvar($1)) { write -dl $+ $readn $scoresfil } }
alias -l hof.size { return $line($twin,0) }
alias -l hof { return $gettok($line($twin,$1),$2,59) }
alias -l scoresfil { return $nopath($ifd($thget(scores),$ifd($tchan($trivchan, 4), TriviaScores.fil))) }
alias -l user.score { return $getvar($1,$unit.prefix($2) $+ score) }
alias -l trivia.on { if (($timer(q $+ $idenn)) || ($timer(end $+ $idenn))) { return $true } }
alias -l question.on { if ($timer(end $+ $idenn)) { return $true } }
alias -l tokq { return $thget(tokq) }
alias -l tok { return $thget(tok $+ $1) }
alias -l question.time { return $calc(($ticks - $thget(Start)) / 1000) }
alias -l te { return $getset(team, $1 $+ $prop) }
alias -l teamscore { return $thget(Score $+ $1) }
alias -l max.hinted { return $iif($calc($thget(Temp.Hints) + 0) > $calc($thuser(Hint) + 0), $thget(Temp.Hints), $thuser(hint)) }
alias -l isteam { return $thget(Team. $+ $1) }
alias -l chkadate { return $iif($getset(status,adate), $+($gettok($1,2,$asc(/)),/,$gettok($1,1,$asc(/)),/,$gettok($1,3,$asc(/))), $1) }
alias -l team { if ($thget(team) == 1) { return $true } }
alias -l tempini { return triviascbb.ini }
alias -l lag { return $iif($thget(lag $+ $1), $thget(lag $+ $1), $getset(lag,$1)) }
alias -l slag { return $getset(lag,$1) }
alias -l tc { return $getset(color, $1 $+ $iif($prop == b, -bold) $+ $iif($prop == u, -underline)) }
alias -l triv { return $getset(trivia, $1) }
alias -l aw { return $getset(award, $1) }
;########################################################
;# MESSAGE COLOR CODE SETTING ALIASES.                  #
;########################################################
alias e1 { return %c1 $+ $1- $+ %c1o }
alias e2 { return %c2 $+ $trivtran($1-) $+ %c2o }
alias trivtran {
  if (!$triv(translate)) return $1-
  if ($isfile($transfile)) {
    var %tran = $read($transfile, wtn, $1- $+ ::=*)
    if ($regex(%tran, /.*::=(.*))) { return $regml(1) }
    if (#* iswm $read($transfile,n,1)) var %nowrite 1
  }
  if (!%nowrite) write $transfile $1- $+ ::= $+ $1-
  return $1-
}
alias untrans {
  if (!$triv(translate)) return $1-
  if ($isfile($transfile)) {
    var %tran = $read($transfile, wtn, *::= $+ $1-)
    if ($regex(%tran, /(.*)::=.*)) { return $regml(1) }
  }
  return $1-
}
alias tranord { return $1 $+ $trivtran($remove($ord($1),$1)) }
alias transfile { return " $+ $triv(translate) $+ " }
;########################################################
;# MESSAGES.                                            #
;########################################################
alias -l msg.ping.reply { return $e1($nick) $+ $e2($chr(44) your ping is) $e1($calc(($ticks - % [ $+ ping. [ $+ [ $nick ] ] ] ) / 1000)) $e2(secs.) }
alias -l msg.answer.correct { return $iif($1,$msg.answer.correct2($2,$3,$4),$e2(Winner:) $e1($getmrank($nick) $replace($nick,>,Guest_)) $iif(!$getset(status,shownone),$e2(Answer:) $e1($trivq.answer)) $iif(!$getset(hide,time),$e2(Time:) $e1($thget(Time))) $iif(!$getset(hide,streak),$e2(Streak:) $e1($getset(Var $+ $idenn, Row))) $iif(!$getset(hide,score),$e2(Points:) $e1($user.score($nick))) $iif(!$getset(hide,wpm),$e2(WPM:) $e1($int($2))) $iif(!$getset(hide,score),$e2(Rank:) $e1($tranord($3)) $iif($4,$e2(Previously:) $e1($tranord($4))))) }
alias -l msg.answer.correct2 { return $e1($getmrank($nick) $nick) $e2(got the answer) $+ $iif(!$getset(status,shownone),$e2(:) $e1($trivq.answer),$e2(.)) $iif(!$getset(hide,time),$e2(in) $e1($thget(Time)) $e2(seconds.)) $iif(!$getset(hide,score),$e2(Points:) $e1($user.score($nick))) $e2(Rank:) $e1($tranord($2)) }
alias -l msg.answer.timeout { return $e2(Time's up! The answer was:) $e1($trivq.answer) }
alias -l msg.answer.timeout.total { return $e2(Time's up! Remaining answers were:) $e1($left($gettotalremain,850)) }
alias -l msg.answer.timeout.wpm { return $e2(Time's up!) }
alias -l msg.answer.timeout.kaos { return $e2(Time's up!) $e1($total.answered) $e2(/) $e1($total.answers) $e2(answered) }
alias -l msg.answer.timeout.pick { return $e2(Time's up! The answer was:) $e1($left($get.picklist,850)) }
alias -l msg.answer.timeout2 { return $e2(Time's up!) }
alias -l msg.question.multi { return $iif($1, $e1($1) $+ $e2(:)) $e2(Multiple Choice:) $e1($right($tok(1),-7)) $+ $e2(;) $e1($get.multianswers) }
alias -l msg.question.wpm { return  $iif($1, $e1($1) $+ $e2(:)) $e1(Type) $+ $e2(:) $e1($tok(2)) }
alias -l msg.question.total { return $iif($1, $e1($1) $+ $e2(:)) $e2(Give all correct responses:) $e1($right($tok(1),-7)) }
alias -l msg.question.kaos { return $iif($1, $e1($1) $+ $e2(:)) $e2(Kaos:) $e1($right($tok(1),-5)) }
alias -l msg.question.points { return $iif($1, $e1($1) $+ $e2(:)) $e2(For) $e1($ifd($thget(temp.points),0)) $e2(point $+ $iif($thget(temp.points) != 1,s) $+ :) $e1($get.question($2-)) }
alias -l msg.question.scramble { return $iif($1, $e1($1) $+ $e2(:)) $iif($getset(status, sayscramble),$e2(Unscramble the following:)) $iif($2,$e1($2) $+ $e2(:)) $e1($scramble($tok(2)) $+ ?) }
alias -l msg.question.standard { return $iif($1, $e1($1) $+ $e2(:)) $e1($get.question($ifd($2,$tok(1)))) }
alias -l msg.question.answer { return $e2(The answer to the last question was $+ :) $e1($thget(answer)) }
alias -l msg.trivia.stats { return $iif($getvar($1,$2 $+ score), $e1($getmrank($1,$iif(!$2,total,$2)) $1) $+ $e2(:) $iif(!$getset(hide,score),$e2(Rank:) $e1($tranord($getrank($1,$2))) $e2(out of) $e1($hof.size) $+ $e2(.) $e2(Current wins:) $e1($getvar($1,$2 $+ score)) $+ $e2(.)) $iif(!$getset(hide,streak),$e2(Best streak:) $e1($getvar($1,$2 $+ streak)) $+ $e2(.)) $iif(!$getset(hide,time),$e2(Best time:) $e1($getvar($1,$2 $+ time)) $e2(secs.)) $iif(!$getset(hide,wpm),$e2(WPM:) $e1($getvar($1,$2 $+ wpm)) $+ $e2(.)) $iif($getvar($1,lastwin), $e2(Last Win:) $e1($chkadate($getvar($1, lastwin))) $+ $e2(.)), $e2(No such user exists.)) }
alias -l msg.trivia.rank { return $iif($user.score($1), $e1($getmrank($1) $1) $+ $e2(:) $iif(!$getset(hide,score),$e2(Current wins:) $e1($user.score($1)) $+ $e2(.)) $iif(($mrankon) && ($getnextmrankat($user.score($1)) != 0),$e2(Next rank:) $e1($getnextmrank($user.score($1))) $iif(!$getset(hide,score),$e2(after:) $e1($calc($getnextmrankat($user.score($1)) - $user.score($1))) $e2(more points.))) $iif(!$getset(hide,score),$e2(Rank:) $e1($tranord($getrank($1,$unit.default))) $e2(out of) $e1($hof.size) $+ $e2(.) $iif(%getrank != 1,$e1($calc(%getnextrankat - $user.score($1))) $e2(points below) $e1(%getnextrankuser) $+ $e2(.))),$e2(Error.)) }
alias -l msg.trivia.state { return $msg.trivia.version $e2(is currently) $e1($trivon) $+ $e2(.) $iif($getset(status,champ),$e2(Champ Mode Set to) $e1($triv(reset)) $e2(Wins.)) $e2(Question file contains) $e1($numq) $e2(lines.) $e1($numl) $e2(questions. Trivia is:) $e1($trivia.onoff) $+ $e2(.) $iif($trivia.on, $iif($question.on,$e2(Time left:) $e1($calc($thget(lagtimedout) - $question.time))) $e2(Question:) $e1($thget(Current)) $+ $e2(/) $+ $e1($thget(Max)) $e2(Team Game:) $e1($team.onoff) $+ $e2(. Trivia Round started by) $e1($thget(SUser)) $e2(on) $e1($thget(STime))) $e2(Bot time is:) $e1($time) }
alias -l msg.trivia.enabled { return $e2(Enabling the trivia. Have an op type:) $e1($pre $+ $gtok(2)) $e2(to disable the bot.) }
alias -l msg.trivia.disabled { return $e2(Disabling the trivia. Have an op type:) $e1($pre $+ $gtok(3)) $e2(to enable the bot.) }
alias -l msg.trivia.victory { return $e2(The game has been beaten by) $e1($1) $e2(all hail the new champ whose name shall reign supreme!) }
alias -l msg.trivia.unactive { return $e2(The game has been disabled due to inactivity.) }
alias -l msg.trivia.emptyoff { return $e2(The game has been disabled due lack of players.) }
alias -l msg.trivia.pause { return $e2(Trivia paused.) $e1($pre $+ $gtok(8)) $e2(to resume.) }
alias -l msg.trivia.resume { return $e2(Trivia resumed.) }
alias -l msg.trivia.started { return $e2(Starting the trivia. Round of) $e1($iif($thget(Max) == Unlimited,$gtok(1,5),$thget(Max))) $e2(questions.) $e1($pre $+ $gtok(6)) $e2(to stop. Total:) $e1($numl) }
alias -l msg.trivia.stopped { return $e2(Stopping the trivia.) $e1($pre $+ $gtok(5) $iif(!$isdis(1),< $+ $trivtran(number) $+ >)) $e2(to restart.) }
alias -l msg.trivia.awarded { return $e1($1) $e2(was awarded) $e1($2) $e2(point $+ $iif($2 > 1,s) $+ . Current Wins:) $e1($user.score($1)) }
alias -l msg.trivia.deducted { return $e1($1) $e2(was deducted) $e1($calc($2 * -1)) $e2(point $+ $iif($2 < -1,s) $+ . Current Wins:) $e1($user.score($1)) }
alias -l msg.trivia.hof { return $msg.trivia.champ(1) $msg.trivia.topstats(score) }
alias -l msg.trivia.error.midq { return $e2(Cannot pause while trivia game has a question issued.) }
alias -l msg.trivia.banned { return $e2(You cannot play $+ $chr(44) you are banned.) }
alias -l msg.trivia.guessed.wpm { return $e2(You already made an attempt.) }
alias -l msg.trivia.guessed { return $e2(You already guessed) $e1($1) $e2(times.) }
alias -l msg.trivia.thanks { return $e2(Thank you for your contribution!) }
alias -l msg.trivia.totalover { return $e2(All correct responses have been given!) }
alias -l msg.trivia.version { return $e1($trivia.name $+ $chr(44) v $+ $trivia.version) }
alias -l msg.trivia.web { return $e2(Get your own copy of) $msg.trivia.version $e2(at) $e1($trivia.web) $e2(.) }
alias -l msg.trivia.onjoin { return $iif($getset(trivia,onjoin),$get.onjoin($getset(trivia,onjoin)),$e2(Welcome) $e1($getmrank($nick) $nick) $+ $e2($chr(44)) $e1($msg.trivia.version) $e2(is activated. Type ') $+ $e1($pre $+ $gtok(33)) $+ $e2(' for a list of commands or just ') $+ $e1($pre $+ $gtok(5)) $+ $e2(' to start a game!)) }
alias -l msg.trivia.records { return $iif(!$getset(hide,streak),$e2(Record streak:) $e1($recordstat(streak)) $e2(of) $e1($hof(1,4)) $+ $e2(.)) $iif(!$getset(hide,time),$e2(Record time:) $e1($recordstat(time)) $e2(of) $e1($hof(1,3)) $+ $e2(.)) $iif(!$getset(hide,wpm),$e2(Record wpm:) $e1($recordstat(WPM)) $e2(of) $e1($hof(1,5)) $+ $e2(.)) }
alias -l msg.trivia.themes { return $e2(Current themes are:) $e1($get.themes) }
alias -l msg.trivia.champ { return $iif($getset(status,champ), $e2(Current champ:) $e1($getset(Champ, $ini($trivini, Champ, 0))) $+ $e2(. $get.champ($1))) }
alias -l msg.trivia.showteams { return $msg.trivia.showteam(1) $msg.trivia.showteam(2) $iif($getset(team, 4-team), $msg.trivia.showteam(3) $msg.trivia.showteam(4)) }
alias -l msg.trivia.showteam { return $iif($get.showteams($1), $e2(Current members of) $e1($te($1)) $e2(are:) $e1($get.showteams($1))) }
alias -l msg.trivia.hintpaused { return $e2(You requested a $pre $+ $gtok(39) less than) $e1($triv(hintpause)) $e2(seconds ago.) }
alias -l msg.trivia.roundscores { return $e2(Current Round:) $e1($get.roundscores) }
alias -l msg.trivia.banlist { return $e2(The following people are banned:) $e1($get.banlist) }
alias -l msg.team.start { return $e2(Team Trivia: ') $+ $e1($pre $+ $gtok(34) 1) $+ $e2(' or ') $+ $e1($pre $+ $gtok(34) 2) $+ $iif($getset(team,4-team),$e2(' or ') $+ $e1($pre $+ $gtok(34) 3) $+ $e2(' or ') $+ $e1($pre $+ $gtok(34) 4)) $+ $e2(' to add to a team.) }
alias -l msg.team.add { return $e2(Team:) $e1($1) $e2(has a new member:) $e1($2) }
alias -l msg.team.joinover { return $e2(I am sorry no more people can join/change at this time.) }
alias -l msg.team.toomany { return $e2(That team currently has enough players.) }
alias -l msg.team.joinbefore { return $e2(Teams are no longer accepting player.) }
alias -l msg.team.alreadyon { return $e2(You are already on that team.) }
alias -l msg.team.score { return $e1($getmrank($nick) $nick) $e2(won. Point for) $e1($te($isteam($nick))) $+ $e2(.) $msg.team.cscore(1,2) $iif($getset(team,4-team), $msg.team.cscore(3,4)) }
alias -l msg.team.cscore { return $e1($te($1)) $e2(has) $e1($thget(Score $+ $1)) $e2(points.) $e1($te($2)) $e2(has) $e1($thget(Score $+ $2)) $e2(points.) }
alias -l msg.team.over { return %c2 $+ $replace($1-, *t1, %c2o $+ $e1($te(1)) $+ %c2,*t2, %c2o $+ $e1($te(2)) $+ %c2,*t3,%c2o $+ $e1($te(3)) $+ %c2,*t4,%c2o $+ $e1($te(4)) $+ %c2) $+ %c2o $+ $e2(!) }
alias -l msg.hint.words { return $e2(Here's $iif($getset(status,sayhintnum),your $tranord($ifd($thuser(hint),$thget(Temp.Hints))), a)  hint $+ $chr(44)) $e2(there $iif($$get.hint(words) == 1,is,are)) $e1($$get.hint(words)) $e2(word $+ $iif($$get.hint(words) != 1,s) in the answer.) }
alias -l msg.hint.vowels { return $e2(Here's $iif($getset(status,sayhintnum),your $tranord($ifd($thuser(hint),$thget(Temp.Hints))), a)  hint $+ $chr(44)) $e2(the vowels are:) $e1($$get.hint(vowels)) }
alias -l msg.hint.last { return $e2(Here's $iif($getset(status,sayhintnum),your $tranord($ifd($thuser(hint),$thget(Temp.Hints))), a)  hint $+ $chr(44)) $e2(the last character in the answer is:) $e1($$get.hint(last)) }
alias -l msg.hint.space { return $e2(Here's $iif($getset(status,sayhintnum),your $tranord($ifd($thuser(hint),$thget(Temp.Hints))), a)  hint $+ $chr(44)) $e2(answer space:) $e1($$get.hint(space)) }
alias -l msg.hint.scramble { return $e2(Here's $iif($getset(status,sayhintnum),your $tranord($ifd($thuser(hint),$thget(Temp.Hints))), a)  hint $+ $chr(44)) $e2(scrambled:) $e1($$get.hint(scramble)) }
alias -l msg.hint.hint { return $e2(Here's $iif($getset(status,sayhintnum),your $tranord($ifd($thuser(hint),$thget(Temp.Hints))), a)  hint $+ $chr(44)) $e1($$get.hint(hint,$1)) }
alias -l msg.features.built { return $e2(Trivia scores updated:) $e1($1) $e2(!) }
alias -l msg.trivia.hof.error { return $e1($pre $+ $gtok(14) < $+ $gtok(1,3) $+ $chr(124) $+ $gtok(2,3) $+ $chr(124) $+ $gtok(3,3) $+ $chr(124) $+ $gtok(4,3) $+ > < $+ $gtok(1,4) $+ $chr(124) $+ $gtok(2,4) $+ $chr(124) $+ $gtok(3,4) $+ $chr(124) $+ $gtok(4,4) $+ $chr(124) $+ $gtok(5,4) $+ >) $e2(to display the hall of fame table of your choice.) }
alias -l msg.trivia.stats.error { return $e1($pre $+ $gtok(11) < $+ $trivtran(player) $+ $chr(124) $+ $trivtran(number) $+ > < $+ $gtok(1,4) $+ $chr(124) $+ $gtok(2,4) $+ $chr(124) $+ $gtok(3,4) $+ $chr(124) $+ $gtok(4,4) $+ $chr(124) $+ $gtok(5,4) $+ >) $e2(to display stats on that individual.) }
alias -l msg.trivia.op.ban { return $e2(User is banned.) }
alias -l msg.trivia.error.ban { return $e2(You need to specify a user or address to ban.) }
alias -l msg.trivia.error.unban { return $e2(You need to specify a user or address to unban.) }
alias -l msg.trivia.op.unban { return $e2(User is unbanned.) }
alias -l msg.trivia.error.badnum { return $e2(You need to specify a valid question number to be asked.) }
alias -l msg.trivia.op.ask { return $e2(Question will be asked.) }
alias -l msg.trivia.error.noquestion { return $e2(You need append the question that is to be added directly into the question file.) }
alias -l msg.trivia.error.nodelim { return $e2(You need at least one delimiter to indicate: question $+ $triv(delimiter) $+ answer) }
alias -l msg.trivia.op.added { return $e2(Question has been added.) }
alias -l msg.trivia.error.nosearch { return $e2(You need at least some search text.) }
alias -l msg.trivia.op.find { return $iif($get.find($1-),$e1($get.find($1-)),$msg.trivia.error.find) }
alias -l msg.trivia.error.find { return $e2(That text was not found.) }
alias -l msg.trivia.error.topx { return $e2(Range too great.) }
alias -l msg.trivia.error.numberrequired { return $e2(You must specify a valid team number for) $e1($1-) $e2(.) }
alias -l msg.trivia.error.playerrequired { return $e2(You must specify a player.) }
alias -l msg.trivia.echoanswer { return $e2(Answer:) $e1($trivq.answer) }
alias msg.trivia.help { return $e2(Commands:) $e1($pre $+ $gtok(6) $pre $+ $gtok(5) $pre $+ $gtok(39) $pre $+ $gtok(34) $pre $+ $gtok(29) $pre $+ $gtok(30) $pre $+ $gtok(31) $pre $+ $gtok(27) $pre $+ $gtok(28) $pre $+ $gtok(14) $pre $+ $gtok(19) $pre $+ $gtok(16) $pre $+ $gtok(21) $pre $+ $gtok(25) $pre $+ $gtok(38) $pre $+ $gtok(23) $pre $+ $gtok(26) $pre $+ $gtok(44) $pre $+ $gtok(37) $pre $+ $gtok(11) $pre $+ $gtok(1) $pre $+ $gtok(3) $pre $+ $gtok(2) $pre $+ $gtok(10) $pre $+ $gtok(41) $pre $+ $gtok(42) $pre $+ $gtok(43) $pre $+ $gtok(35) $pre $+ $gtok(36) $pre $+ $gtok(4) $pre $+ $gtok(7) $pre $+ $gtok(8) $pre $+ $gtok(62)) $chr(124) $e1($pre $+ $gtok(33) < $+ $trivtran(command) $+ >) $e2(for specific help. Some commands may be disabled.) }
;########################################################
;# Help structure.                                      #
;########################################################
alias -l givehelp {
  if (!$1-) {
    inform $e2(Commands:) $e1($pre $+ $gtok(6) $pre $+ $gtok(5) $pre $+ $gtok(39) $pre $+ $gtok(34) $pre $+ $gtok(29) $pre $+ $gtok(30) $pre $+ $gtok(31) $pre $+ $gtok(27) $pre $+ $gtok(28) $pre $+ $gtok(14) $pre $+ $gtok(19) $pre $+ $gtok(16) $pre $+ $gtok(21) $pre $+ $gtok(25) $pre $+ $gtok(38) $pre $+ $gtok(23) $pre $+ $gtok(26) $pre $+ $gtok(44) $pre $+ $gtok(37) $pre $+ $gtok(11) $pre $+ $gtok(1) $pre $+ $gtok(3) $pre $+ $gtok(2) $pre $+ $gtok(10) $pre $+ $gtok(41) $pre $+ $gtok(42) $pre $+ $gtok(43) $pre $+ $gtok(35) $pre $+ $gtok(36) $pre $+ $gtok(4) $pre $+ $gtok(7) $pre $+ $gtok(8) $pre $+ $gtok(62))
    inform $e1($pre $+ $gtok(33) < $+ $trivtran(command) $+ >) $e2(for specific help. Some commands may be disabled.)
  }
  var %ctok = $iif($pre $+ * iswm $1, $ctok($right($1,$calc(-1 * $len($pre)))), $ctok($1))
  if ((%ctok == 1)) { inform $e1($gtok(%ctok) -----) $e2(Displays the state of the bot) }
  if ((%ctok == 6)) { inform $e1($gtok(%ctok) ---) $e2(Stops trivia) }
  if ((%ctok == 3)) { inform $e1($gtok(%ctok) ----) $e2(Enables trivia bot) }
  if ((%ctok == 2)) { inform $e1($gtok(%ctok) ---) $e2(Disables trivia bot) }
  if ((%ctok == 7)) { inform $e1($gtok(%ctok) ----) $e2(Pauses trivia bot) }
  if ((%ctok == 8)) { inform $e1($gtok(%ctok) ----) $e2(Resumes trivia bot) }
  if ((%ctok == 4)) { inform $e1($gtok(%ctok) < $+ $trivtran(command) $+ > -) $e1($gtok(1,2)) $+ $e2($chr(44)) $e1($gtok(2,2)) $+ $e2($chr(44)) $e1($gtok(3,2)) $+ $e2($chr(44)) $e1($gtok(4,2)) $+ $e2($chr(44)) $e1($gtok(5,2)) $+ $e2($chr(44)) $e1($gtok(6,2)) $+ $e2($chr(44)) $e1($gtok(7,2)) $+ $e2($chr(44)) $e1($gtok(8,2)) $+ $e2($chr(44) commands to allow ops to control the trivia bot.) }
  if ((%ctok == 5)) { inform $e1($gtok(%ctok) x --) $e2(Starts trivia, x can be a number, "unlimited", <theme> or "team" for team mode) }
  if ((%ctok == 39)) { inform $e1($gtok(%ctok) ------) $e2(Gives a hint) }
  if ((%ctok == 42)) { inform $e1($gtok(%ctok) ------) $e2(Gives the last character of the answer) }
  if ((%ctok == 41)) { inform $e1($gtok(%ctok) ------) $e2(Gives the number of words in the answer) }
  if ((%ctok == 43)) { inform $e1($gtok(%ctok) ------) $e2(Gives the vowels of the answer) }
  if ((%ctok == 34)) { inform $e1($gtok(%ctok) x ----) $e2(Joins a team, must be in team mode, x can be a 1 or 2) }
  if ((%ctok == 29)) { inform $e1($gtok(%ctok) -------) $e2(Allows you to add questions: $pre $+ $gtok(29) What is the square root of 4*two*2) }
  if ((%ctok == 30)) { inform $e1($gtok(%ctok) ----) $e2(Lets you report problems with the questions: $pre $+ $gtok(30) The square root of 4 is also -2) }
  if ((%ctok == 31)) { inform $e1($gtok(%ctok) -----) $e2(Checks your lag from the bot) }
  if ((%ctok == 27)) { inform $e1($gtok(%ctok) ---) $e2(Displays the version of the bot) }
  if ((%ctok == 28)) { inform $e1($gtok(%ctok) -------) $e2(Displays the web page for the bot) }
  if ((%ctok == 14)) { inform $e1($gtok(%ctok) < $+ $gtok(1,3) $+ $chr(124) $+ $gtok(2,3) $+ $chr(124) $+ $gtok(3,3) $+ $chr(124) $+ $gtok(4,3) $+ > < $+ $gtok(1,4) $+ $chr(124) $+ $gtok(2,4) $+ $chr(124) $+ $gtok(3,4) $+ $chr(124) $+ $gtok(4,4) $+ $chr(124) $+ $gtok(5,4) $+ > -------) $e2(Displays the hall of fame, for requested entry) }
  if ((%ctok == 19)) { inform $e1($gtok(%ctok) ---) $e2(Displays the record times. Same as $pre $+ $gtok(14) $gtok(2,3)) }
  if ((%ctok == 16)) { inform $e1($gtok(%ctok) --) $e2(Displays the record streaks. Same as $pre $+ $gtok(14) $gtok(3,3)) }
  if ((%ctok == 21)) { inform $e1($gtok(%ctok) ----) $e2(Displays the record words per minute. Same as $pre $+ $gtok(14) $gtok(4,3)) }
  if ((%ctok == 25)) { inform $e1($gtok(%ctok) ---) $e2(Displays the record $gtok(2,3) & $gtok(3,3) & $gtok(4,3)) }
  if ((%ctok == 23)) { inform $e1($gtok(%ctok) ----) $e2(Displays the bot's server) }
  if ((%ctok == 26)) { inform $e1($gtok(%ctok) -----) $e2(Displays the champ stats) }
  if ((%ctok == 36)) { inform $e1($gtok(%ctok)) $e2(Displays the scores for the current round.) }
  if ((%ctok == 35)) { inform $e1($gtok(%ctok)) $e2(Displays the teams and which players are on each.) }
  if ((%ctok == 44)) { inform $e1($gtok(%ctok) ----) $e2(Repeats the question) }
  if ((%ctok == 37)) { inform $e1($gtok(%ctok) ----) $e2(Provides the answer to the last question to an op who requests it) }
  if ((%ctok == 38)) { inform $e1($gtok(%ctok) ----) $e2(After half the time to answer has expired allows an instant timeout.) }
  if ((%ctok == 10)) { inform $e1($gtok(%ctok) ----) $e2(Lists available themes) }
  if ((%ctok == 11)) { inform $e1($gtok(%ctok) ------) $e2(Returns your current stats, or $pre $+ $gtok(11) <player> for somebody else) }
  if ((%ctok == 62)) { inform $e1($gtok(%ctok) ----) $e2(Displays score required for next promotion.) }
}
;########################################################
;# MESSAGE PROCESSES.                                   #
;########################################################
alias -l get.question {
  var %gq $1-
  if (!$getset(status,noautoqm)) { var %aqm = 1 }
  if ($right(%gq,1) isin :!?.-) { var %aqm = 0 }
  if ($right(%gq,1) isin -) { var %gq = $left(%gq,-1) }
  if ($thget(temp.bonus) == S)  { %gq = $scramble(%gq) }
  if ($thget(temp.bonus) == R)  { %gq = $reverse(%gq) }
  if ($thget(temp.bonus) == G)  { %gq = $scatter(75,%gq) }
  return %gq $+ $iif(%aqm,?)
}
alias -l get.banlist {
  var %i = 1, %b.temp
  while ($getset(banned,%i)) {
    var %b.temp = %b.temp $getset(banned,%i)
    inc %i
  }
  return %b.temp
}
alias -l get.roundscores {
  if ($window(@round $+ $idenn)) { window -c @round $+ $idenn }
  window -hn @round $+ $idenn
  .timer 1 0 window -c @round $+ $idenn
  var %i = 1
  while ($hmatch(Trivia $+ $idenn, Score.*, %i)) {
    var %j = $line(@round $+ $idenn,0)
    while (( $hget(Trivia $+ $idenn, $hmatch(Trivia $+ $idenn, Score.*, %i)) > $thget(Score. $+ $line(@round $+ $idenn, %j))) && (%j >= 1)) { dec %j }
    iline @round $+ $idenn $calc(%j + 1) $remove($hmatch(Trivia $+ $idenn, Score.*, %i),Score.)
    inc %i
  }
  var %roundscores
  %i = 1
  while (%i <= 15) {
    %roundscores = %roundscores $iif($line(@round $+ $idenn,%i),$line(@round $+ $idenn,%i) $+ - $+ $thget(Score. $+ $line(@round $+ $idenn,%i)))
    inc %i
  }
  return %roundscores
}
alias sortroundscores {
  var %j = 1
  while (%j <= $line(@round $+ $idenn,0)) {
    var %k = %j
    while (%k <= $line(@round $+ $idenn,0)) {
      if ($thget(Score. $+ $line(@round $+ $idenn, %j)) > $thget(Score. $+ $line(@round $+ $idenn, %k))) {
        var %temp.name = $line(@round $+ $idenn, %j)
        rline @round $+ $idenn %j $line(@round $+ $idenn, %k)
        rline @round $+ $idenn %j %temp.name
      }
      inc %k
    }
    inc %j
  }
}
alias get.showteams {
  var %i = 1
  while ($hmatch(Trivia $+ $idenn, Team.*, %i)) {
    if ($isteam($remove($hmatch(Trivia $+ $idenn, Team.*, %i),Team.)) == $1) { var %temp.team = %temp.team $remove($hmatch(Trivia $+ $idenn, Team.*, %i),Team.) }
    inc %i
  }
  return %temp.team
}
alias -l get.champ {
  if (($setini(Champ,0) <= 0) || (!$getset(status,champ))) { return }
  var %temp.champ, %i = $calc($ini($trivini, Champ, 0) - 1)
  while ((%i >= 1) && (!$1)) {
    var %temp.champ = %temp.champ $getset(Champ, %i)
    dec %i
  }
  return %temp.champ
}
alias -l get.multianswers {
  var %i 2, %answers.t
  if ($window(@multianswer)) { window -c @multianswer }
  window -h @multianswer
  .timer 1 0 window -c @multianswer
  while ($tok(%i)) {
    aline @multianswer $tok(%i)
    inc %i
  }
  filter -wwct 1 13 @multianswer @multianswer *
  var %i 2
  var %answers.t $line(@multianswer,1)
  while ($line(@multianswer, %i)) { var %answers.t = %answers.t $+ , $line(@multianswer, %i), %i = $calc(%i + 1) }
  return %answers.t
}
alias -l get.themes {
  var %i = 1
  while ($getset(triviamode $+ %i, name)) {
    var %temp.themes = %temp.themes $getset(triviamode $+ %i, name)
    inc %i
  }
  return $e1(%temp.themes)
}
alias -l get.onjoin {
  return %c2 $+ $replace($1-,$chr(35),$+(%c2o,%c1,$chan,%c1o,%c2),*, $+(%c2o,%c1,$getmrank($nick) $nick,%c1o,%c2),@, $+(%c2o,%c1,$tranord($getrank($nick,$unit.default)),%c1o,%c2),^, $+(%c2o,%c1,$ifd($getvar($nick,score),0),%c1o,%c2)) $+ %c2o
}
alias -l get.picklist {
  if ($tokq <= 2) return $tok(2)
  var %i = 2, %picklist
  while (%i <= $tokq) {
    %picklist = %picklist $tok(%i)
    if (%i < $calc($tokq - 1)) { %picklist = %picklist $+ $chr(44) }
    if (%i == $calc($tokq - 1)) { %picklist = %picklist $trivtran(and) }
    inc %i
  }
  return %picklist

}
;########################################################
;# HTML BUILD                                           #
;########################################################
alias bgcolor { return #000000 }
alias textcolor { return #339933 }
alias linkcolor { return #33FF00 }
alias alinkcolor { return #666600 }
alias vlinkcolor { return #666666 }

alias htmlbuild {
  var %start.ticks = $ticks
  set %htmlfile " $+ $mircdir $+ \ $+ $ifd($getset(build,genname),triv.htm) $+ "
  sort score $unit.default
  if ($exists(%htmlfile)) { .remove %htmlfile }
  write %htmlfile <HTML><head><title> $+ $iden $iif($network,$trivtran(Trivia Scores on) $network) $+ </title></head>
  write %htmlfile <body bgcolor=" $+ $bgcolor $+ " text=" $+ $textcolor $+ " link=" $+ $linkcolor $+ " alink=" $+ $alinkcolor $+ " vlink=" $+ $vlinkcolor $+ ">
  write %htmlfile $trivtran(The scores file was compiled by:) $strip($msg.trivia.version) <br>
  write %htmlfile $trivtran(This file was created on:) $time $chkadate($date) <br>
  write %htmlfile <table BORDER COLS=5 WIDTH="80%" ><tr><tr>
  write %htmlfile <th> $+ $trivtran(Ranking) $+ </th><th> $+ $trivtran(Name) $+ </th> $+ $iif(!$getset(hide,score),<th> $+ $trivtran(Score) $+ </th>) $+ $iif(!$getset(hide,time),<th> $+ $trivtran(Best Time) $+ </th>) $+ $iif(!$getset(hide,streak),<th> $+ $trivtran(Best Streak) $+ </th>) $+ $iif(!$getset(hide,wpm),<th> $+ $trivtran(Best WPM) $+ </th>) $+ </tr>
  var %i = 1, %j = $hof.size
  if ($getset(build,top) isnum 1 - %j) { %j = $getset(build,top) }
  if ($version >= 6.15) {
    set %count.num.t %i
    filter -wkr %i $+ - $+ %j $twin htmlprocess
    unset %count.num.t
  }
  else {
    while (%i <= %j) {
      write %htmlfile <tr><th> $+ %i $+ </th><td> $+ $hof(%i,1) $+ </td> $+ $iif(!$getset(hide,score),<td> $+ $hof(%i,$gttok($unit.mark $+ score)) $+ </td>) $+ $iif(!$getset(hide,time),<td> $+ $hof(%i,$gttok($unit.mark $+ time)) $+ </td>) $+ $iif(!$getset(hide,streak),<td> $+ $hof(%i,$gttok($unit.mark $+ streak)) $+ </td>) $+ $iif(!$getset(hide,wpm),<td> $+ $hof(%i,$gttok($unit.mark $+ wpm)) $+ </td>) $+ </tr>
      inc %i
    }
  }
  write %htmlfile </table><br>
  write %htmlfile $trivtran(Made with) <a href=" $+ $trivia.web $+ " "target="_top"> $+ $strip($msg.trivia.version) $+ </a><br>
  echo -a $e2(Finished:) $e1(%htmlfile) $e2(is written. In) $e1($calc(($ticks - %start.ticks) / 1000)) $+ $e2(secs.)
  unset %htmlfile
}
alias htmlprocess {
  write %htmlfile <tr><th> $+ %count.num.t $+ </th><td> $+ $gettok($1,1,59) $+ </td> $+ $iif(!$getset(hide,score),<td> $+ $gettok($1,$gttok($unit.mark $+ score),59) $+ </td>) $+ $iif(!$getset(hide,time),<td> $+ $gettok($1,$gttok($unit.mark $+ time),59) $+ </td>) $+ $iif(!$getset(hide,streak),<td> $+ $gettok($1,$gttok($unit.mark $+ streak),59) $+ </td>) $+ $iif(!$getset(hide,wpm),<td> $+ $gettok($1,$gttok($unit.mark $+ wpm),59) $+ </td>) $+ </tr>
  inc %count.num.t
}

alias xmlbuild {
  if ($version < 6.15) {
    echo -a Update to a later version of mIRC. This code will not work with versions prior to 6.15.
    return
  }
  var %start.ticks = $ticks
  set %xmlfile " $+ $mircdir $+ \ $+ triv-rss-091.xml $+ "
  sort score $unit.default
  if ($exists(%xmlfile)) { .remove %xmlfile }

  write %xmlfile <?xml version="1.0" ?>
  write %xmlfile <rss version="0.91">
  write %xmlfile  	<channel>
  write %xmlfile  		<title> $trivia.name </title>
  write %xmlfile 		<link> $trivia.web </link>
  write %xmlfile 		<description>Latest Scores</description>
  write %xmlfile 		<language>en-us</language>
  write %xmlfile 		<copyright>Copyright $asctime(yyyy) $+ </copyright>
  write %xmlfile 		<lastBuildDate> $asctime($gmt, ddd $+ $chr(44) dd mmm yyyy HH:nn:ss) GMT </lastBuildDate>

  var %i = 1, %j = $hof.size
  if ($getset(build,top) isnum 1 - %j) { %j = $getset(build,top) }
  set %count.num.t %i
  filter -wkr %i $+ - $+ %j $twin xmlprocess
  unset %count.num.t

  write %xmlfile  		</channel>
  write %xmlfile  	</rss>

  echo -a $e2(Finished:) $e1(%xmlfile) $e2(is written. In) $e1($calc(($ticks - %start.ticks) / 1000)) $+ $e2(secs.)
  unset %xmlfile
}
alias xmlprocess {
  write %xmlfile 		<item>
  write %xmlfile 			<title> $+ $gettok($1,1,59) $+ </title>
  write %xmlfile 			<description> Score: $gettok($1,$gttok($unit.mark $+ score),59) Record Time: $gettok($1,$gttok($unit.mark $+ time),59) Streak: $gettok($1,$gttok($unit.mark $+ streak),59) WPM: $gettok($1,$gttok($unit.mark $+ wpm),59)  </description>
  write %xmlfile 			<link> $+ $trivia.web $+ </link>
  write %xmlfile 			</item>
  inc %count.num.t
}
alias xmlbuildon { setset build xml 1 }
alias xmlbuildoff { setset build xml 0 }

alias unit.mark { return $iif($unit.default != total,$unit.default) }
alias htmltrigger {
  if ($getset(build,xml)) { xmlbuild }
  if ($getset(build,generate)) { htmlbuild }
  if (($getset(build,auto)) && ($exists($+(",$triv(dir),\,ftpbatch.txt,")))) { run -n ftp $+(-s:,",$triv(dir),\,ftpbatch.txt") }
  if (($getset(build,copy)) && ($exists(" $+ $getset(build,from) $+ ")) && ($exists(" $+ $getset(build,to) $+ "))) { .copy -o " $+ $getset(build,from) $+ " " $+ $getset(build,to) $+ \ $+ $nopath($getset(build,from)) $+ " }
  if ($getset(build,web)) { tsay $msg.features.built($getset(build,web)) }
  award HTMLUpdate 0
}
;########################################################
;# SPECIAL COMMANDS.                                    #
;# /find <text> : Finds the text in your current        #
;#     question files for the channel.                  #
;# /add <question> : directly adds the given question.  #
;# /ask <question|#> : Force asks a given question.     #
;# /sortfile : Sorts the selcted file alphanumerically. #
;# /killdup : Kills exact duplicate questions in file.  #
;# /killfixdup : Uses internal fix routine to kill same #
;#      questions with a little more checking.          #
;# /reformfile <filename> <regex> <regex> : Uses the    #
;#      regsub command to reform a file. For example:   #
;#      /reformfile q.txt ([^\|]+)\|([^\*]+) \2*\1      #
;#      would change q.txt from answer|question form to #
;#      question*answer form. You need to know regex.   #
;# /tpurge <#> : Moves everybody with less that # point #
;#       to a secondary file called backburner. If they #
;#       score another point they will be restored.     #
;# /tdpurge <#> : Anybody who hasn't played in # days.  #
;# /copyentry <filefrom> <fileto> <nickname> : Copies.  #
;# /debackburn : Reverses effect of /tpurge commands.   #
;# /mergefiles <filefrom> <fileto> : Merges two score   #
;#       files into one score file.                     #
;# /tfind : finds score files that should be merged.    #
;# /tmerge <fromplayer> <toplayer> : merge player score #
;# /trename <fromplayer> <toplayer> : renames player    #
;# /triviaad <#> <message> : displays message every <#> #
;#       of minutes.                                    #
;# /triviaad2 <#> <message> : Same but colored.         #
;# /truntimes <timeon> <timeoff> : turns bot on and off #
;#       only plays during the given times.             #
;########################################################
alias find { echo $get.find($1-) }
alias add { if ($exists($qfile(1))) write $qfile(1) $1- }
alias openquestions {
  if ($exists($qfile(1))) run $qfile(1)
}
alias ask {
  var %asknm = 1
  while ($thget(Ask $+ %asknm)) { inc %asknm }
  if ($hget(Trivia $+ $idenn)) { thset Ask $+ %asknm $iif($1-,$1-,$$?="Force which question number(#) or ask what question(Question*Answer)?") }
}
alias sortfile { 
  var %file = " $+ $sfile($mircdir) $+ "
  filter -ffct 1 13 %file %file *
}
alias killdup { 
  var %file = " $+ $sfile($mircdir) $+ ", %i = 0
  window -hn @temp.window
  window -hn @temp.windowfile
  filter -fwct 1 13 %file @temp.windowfile *
  while ($line(@temp.windowfile,0) >= %i) {
    var %line = $line(@temp.windowfile,%i)
    if (%line) { aline -n @temp.window %line }
    unset %line
    inc %i
  }
  filter -wfc @temp.window %file *
  window -c @temp.window
  window -c @temp.windowfile
}
alias killfixdup { 
  var %file = $sfile($mircdir), %i = 0, %fixed = 0
  window -hn @temp.windowfix
  window -hn @temp.windowfile
  .timer 1 0 window -c @temp.windowfix
  .timer 1 0 window -c @temp.windowfile
  filter -fwct 1 13 " $+ %file $+ " @temp.windowfile *
  while ($line(@temp.windowfile,0) >= %i) {
    if ($line(@temp.windowfile,%i)) {
      aline -n @temp.windowfix $fix($line(@temp.windowfile,%i))
      if (%fixed != $line(@temp.windowfix,0)) { write $nopath(%file) $+ .fix $line(@temp.windowfile,%i) }
      var %fixed = $line(@temp.windowfix,0)
    }
    inc %i
  }
  echo -s Killed dups, saved as %file $+ .fix $+ !
}
alias reformfile {
  if (!$exists($1)) { echo File not found. | return }
  var %i = 1, %replace, %matchez = 0
  while (%i <= $lines($1)) {
    if ($regsub($read($1,%i),$2, $3, %replace)) { write $1 $+ .ref %replace | inc %matchez }
    inc %i
  }
  echo Done, %matchez lines replaced, saved as $1 $+ .ref
}
alias tpurge {
  var %i = 1
  sort score
  while ($hof(%i,1)) {
    if ($hof(%i,2) <= $$1) { copyentry $$scoresfil $$tempfil $hof(%i,1) }
    inc %i
  }
}
alias tdpurge {
  var %i = 1
  sort score
  while ($hof(%i,1)) {
    if ($round($calc(($ctime($date) - $ctime($hof(%i,6)))/86400),0) > $$1) { copyentry $$scoresfil $$tempfil $hof(%i,1) }
    inc %i
  }
}
alias copyentry {
  if (!$exists($1)) { echo -a $1 does not exist. | return }
  if (!$exists($2)) { echo -a $2 does not exist. | return }
  write $2 $$read($1, w, $3 $+ ;*)
  write -dl $+ $$readn $1
}
alias debackburn { mergefiles $tempfil $scoresfil }
alias mergefiles {
  echo Merging files $1 and $2
  if (!$exists($1)) { echo -a $1 does not exist. | return }
  if (!$exists($2)) { echo -a $2 does not exist. | return }
  while ($lines($1) > 0) {
    if ($numtok($read($1,1),$asc(;)) <= 1) { echo -a ERROR, file does not appear to be standard format. | return }
    var %player = $gettok($read($1,1),1,$asc(;))
    mergeentry $1 $2 %player
  }
}
alias mergeentry {
  if (!$exists($1)) { echo -a $1 does not exist. | return }
  if (!$exists($2)) { echo -a $2 does not exist. | return }
  var %merger = $read($1, wnt, $3 $+ ;*)
  var %other = $read($2, wnt, $3 $+ ;*)
  var %merger.line = $readn
  if (%merger) {
    if (%other) {
      write $2 PlayerMoving= $+ %merger
      write -d1 $+ %merger.line $1
      tmergeplayers PlayerMoving= $+ $3 $3
    }
    else copyentry $1 $2 $3
  }
}
alias tfind {
  if ($exists($scoresfil)) {
    echo -a Finding Duplicate Entries
    window -h $twin
    filter -fwc $scoresfil $twin
    var %k = $line($twin,0)
    while (%k > 0) {
      %hostname = $replace($mask($gettok($line($twin,%k), $gttok(address), 59),2),.,\.,*,.*)
      if (%hostname) {
        var %j = 1
        var %fline = $fline($twin,$str([^;]*;,7) $+ %hostname $+ ;.*,1,2)
        while (%fline) {
          if (%j == 2) {
            echo -a Multiple references:
            echo -a ... $gettok($line($twin,%prev.fline),1,59) ... $gettok($line($twin,%prev.fline),$gttok(address),59)
          }
          if (%j >= 2) {
            echo -a ... $gettok($line($twin,%fline),1,59) ... $gettok($line($twin,%fline),$gttok(address),59)
            dline $twin %prev.fline
          }
          inc %j
          var %prev.fline = %fline
          var %fline = $fline($twin,$str([^;]*;,7) $+ %hostname $+ ;.*,2,2)
        }
      }
      dec %k
    }
  }
  echo -a To combine entries use: /tmerge <from-nick> <to-nick>
  window -c $twin
}
alias tmerge {
  tmergeplayers $1 $2
  tsay $msg.trivia.stats($2)
}
alias tmergeplayers {
  if (($$getvar($$1,score)) && ($$getvar($$2,score))) {
    var %i = $numtok($unit.tokens, $asc(.))
    while (%i > 0) {
      var %unit = $gettok($unit.tokens, %i, $asc(.))
      if ($getvar($1, %unit) == $eval($ $+ get. $+ %unit,2)) {
        if ($getvar($2, %unit) == $eval($ $+ get. $+ %unit,2)) {
          setvar $2 %unit $+ score $calc($getvar($2,%unit $+ score) + $getvar($1,%unit $+ score))
          if ($getvar($1, %unit $+ WPM) > $getvar($2,%unit $+ WPM)) { setvar $2 %unit $+ WPM $getvar($1, %unit $+ WPM) }
          if ($getvar($1, %unit $+ streak) > $getvar($2,%unit $+ streak)) { setvar $2 %unit $+ streak $getvar($1, %unit $+ streak) }
          if ($getvar($1, %unit $+ time) < $getvar($2,%unit $+ time)) { setvar $2 %unit $+ time $getvar($1, %unit $+ time) }
        }
        else {
          setvar $2 %unit $+ score $getvar(%unit $+ score)
          setvar $2 %unit $+ WPM $getvar(%unit $+ WPM)
          setvar $2 %unit $+ streak $getvar(%unit $+ streak)
          setvar $2 %unit $+ time $getvar(%unit $+ time)
        }
      }
      dec %i
    }
    setvar $2 score $calc($getvar($2,score) + $getvar($1,score))
    if ($getvar($1, wpm) > $getvar($2,wpm)) { setvar $2 wpm $getvar($1, wpm) }
    if ($getvar($1, streak) > $getvar($2,streak)) { setvar $2 streak $getvar($1, streak) }
    if ($getvar($1, time) < $getvar($2,time)) { setvar $2 time $getvar($1, time) }
    setvar $2 admin $or($getvar($1,admin),$getvar($2,admin))
    deleteplayer $1
  }
}
alias trename {
  setvar $1 name $2
  tsay $msg.trivia.stats($2)
}
alias triviad {
  if (($1 >= 1) && ($2)) { .timertriviaad 0 $calc($$1 * 60) timer.ad $chan $2- }
  else { .timertriviaad off } 
}
alias triviad2 { 
  if (($1 >= 1) && ($2)) { .timertriviaad 0 $calc($$1 * 60) msg $chan $e1($2-) } 
  else { .timertriviaad off } 
}
alias truntimes {
  if (($regex($1,/\d+:\d+/)) && ($regex($2,/\d+:\d+/))) {
    .timertriviarunon -o $1 1 1 tboton $1
    .timertriviarunoff -o $2 1 1 tbotoff $2
  }
  else { .timertriviarun* off }
}
alias tboton {
  .timertriviarunon -o $1 1 1 tboton $1
  setset status bot 1
  trivia
}
alias askrotate {
  set %askcount $calc((%askcount + 1) % $numq)
  ask %askcount
}

alias tbotoff {
  .timertriviarunoff -o $1 1 1 tbotoff $1
  if ($trivia.on) { strivia }
  setset status bot 0
}
alias tempfil { return  backburner.txt }
alias timer.ad { if (!$trivia.on) { msg $1 $e1($2-) } }
;########################################################
;# DIALOGS.                                             #
;########################################################
dialog trivset {
  title "Trivia Settings"
  size -1 -1 912 544
  option pixels
  tab General, 1, 4 8 896 523
  box Channels, 9, 12 36 502 108, tab 1
  text Delimiter, 10, 22 443 68 20, tab 1
  text Add/Report, 11, 18 405 92 20, tab 1
  button Add, 24, 24 204 64 20, tab 1
  edit , 30, 84 113 418 22, tab 1 autohs
  edit $triv(delimiter), 31, 20 463 34 24, tab 1
  edit $triv(additions), 32, 112 405 86 24, tab 1 autohs
  edit $triv(report), 33, 204 405 86 24, tab 1 autohs
  edit $triv(dir), 35, 100 371 402 24, tab 1 autohs
  text Percent Hint, 14, 532 84 68 20, tab 1
  edit $triv(perchint), 99, 676 84 40 26, tab 1
  text Number of hints, 15, 532 66 136 20, tab 1
  edit $triv(numhint), 861, 676 58 40 26, tab 1
  text Hint Reduction, 16, 536 352 108 20, tab 1
  edit $triv(DPH), 863, 704 356 48 24, tab 1
  text Points per answer, 17, 536 326 148 20, tab 1
  edit $triv(PPQ), 65, 704 326 48 24, tab 1
  list 108, 82 48 424 64, tab 1 size
  button Add, 115, 18 60 58 20, tab 1
  button Remove, 119, 18 88 62 20, tab 1
  text Channel:, 125, 16 116 62 20, tab 1
  edit , 132, 96 300 398 24, tab 1 autohs
  box "Points", 133, 520 308 308 76, tab 1
  box "Global", 134, 12 344 496 152, tab 1
  button "Scores", 141, 36 304 56 20, tab 1
  button "Define", 20, 424 440 55 21, tab 1
  check "Trivia Ranks", 148, 364 416 116 24, tab 1
  check Crosshatch, 47, 532 124 116 20, tab 1
  text Chr, 21, 652 124 31 26, tab 1
  edit , 961, 684 124 28 26, tab 1
  box "Hints", 80, 524 48 304 256, tab 1
  radio "Scatter", 58, 612 196 75 20, group tab 1
  radio "Plot", 129, 692 196 75 20, tab 1
  radio "Basic", 130, 536 196 75 20, tab 1
  text $hint.example, 199, 536 172 274 20, tab 1
  check "Say Hint Number", 147, 532 144 160 24, tab 1
  radio "Standard", 149, 532 248 92 20, group tab 1
  radio "Last Letter", 150, 624 252 100 20, tab 1
  radio "Vowels", 151, 536 276 72 20, tab 1
  radio "Random", 152, 624 280 88 20, tab 1
  text "First Hint Type", 153, 536 224 122 20, tab 1
  button "Remove", 12, 24 272 64 20, tab 1
  list 34, 92 200 410 92, tab 1 sort size
  box "Channel Properties", 83, 12 144 498 192, tab 1
  edit $triv(translate), 131, 232 464 272 24, tab 1 autohs
  button "Translation File", 136, 108 468 115 20, tab 1
  button "Trivia Dir", 13, 20 376 67 17, tab 1
  text "Nick", 543, 28 168 34 20, tab 1
  edit "", 544, 64 168 76 25, tab 1 autohs
  text "Network", 66, 160 168 70 20, tab 1
  edit "", 67, 236 164 116 25, tab 1 autohs
  check Auto-Hint, 41, 532 103 132 20, tab 1
  tab Options, 6
  text questions, 18, 72 219 80 21, tab 6
  check No-activity off, 88, 20 187 140 20, tab 6
  edit $triv(naoff), 89, 16 215 50 32, tab 6
  text seconds, 19, 250 211 76 25, tab 6
  check Hint-Pause, 96, 200 185 140 20, tab 6
  edit $triv(hintpause), 97, 198 211 50 32, tab 6
  check Echo Answer, 40, 20 60 140 20, tab 6
  check Timeout Answer, 45, 200 106 140 20, tab 6
  check Join Message, 46, 12 336 120 20, tab 6
  check Traditional win, 48, 20 105 140 20, tab 6
  check Auto-Start, 49, 385 60 140 20, tab 6
  check Say Scramble:, 53, 202 60 140 20, tab 6
  check Showteam End, 55, 200 81 140 20, tab 6
  check Answer Space, 56, 384 127 140 20, tab 6
  check No Mid-Match, 57, 574 160 140 20, tab 6
  check Show Matched, 59, 200 131 140 20, tab 6
  check Use Adate, 60, 20 82 140 20, tab 6
  check No ? end, 830, 574 60 140 20, tab 6
  check No Spell Correct, 817, 574 140 140 20, tab 6
  check "Monday Week", 126, 384 83 140 20, tab 6
  check Limit Guesses, 51, 384 166 140 20, tab 6
  edit $triv(limitguess), 144, 384 191 36 32, tab 6
  check Round HoF, 52, 384 105 140 20, tab 6
  edit , 22, 12 368 728 89, tab 6 read multi autovs
  edit $triv(onjoin), 138, 148 336 596 29, tab 6 autohs
  check No Partial Match, 43, 574 180 140 20, tab 6
  text "tries", 146, 420 192 58 28, tab 6
  check No Decheater, 44, 574 80 140 20, tab 6
  check No Color Short, 61, 574 100 140 20, tab 6
  check "Score", 106, 28 292 84 20, tab 6
  check "Time", 169, 120 292 80 20, tab 6
  check "Streak", 171, 204 292 80 20, tab 6
  check "WPM", 173, 288 292 72 20, tab 6
  box "Hide Stat", 174, 12 264 368 60, tab 6
  check "No Catergories", 62, 574 120 140 20, tab 6
  check "Empty Off", 54, 20 127 140 20, tab 6
  check "No Bonus", 50, 574 200 140 20, tab 6
  check "No Q number", 63, 574 220 140 20, tab 6
  box Settings, 70, 8 40 732 288, tab 6
  check "Keep Ask", 156, 20 150 140 20, tab 6
  check "Show Nothing", 143, 200 156 140 20, tab 6
  tab Defaults, 2
  box , 23, 280 63 322 80, tab 2
  box , 25, 602 67 174 76, tab 2
  check Colors, 116, 280 48 88 20, tab 2 push
  text Primary, 110, 286 74 60 17, tab 2
  text Secondary, 120, 286 110 84 21, tab 2
  edit $tc(1), 121, 372 74 35 28, tab 2 read
  edit $tc(2), 122, 376 110 35 28, tab 2 read
  edit $tc(3), 123, 607 74 43 28, tab 2 read
  edit $tc(4), 124, 607 110 43 28, tab 2 read
  check B, 117, 541 74 24 24, tab 2 push
  check U, 118, 568 74 24 24, tab 2 push
  check B, 127, 541 110 24 24, tab 2 push
  check U, 128, 568 110 20 24, tab 2 push
  combo 111, 412 74 124 240, tab 2 size drop
  combo 112, 412 110 124 240, tab 2 size drop
  combo 113, 652 74 120 240, tab 2 size drop
  combo 114, 652 110 120 240, tab 2 size drop
  box Time, 26, 12 188 264 244, tab 2
  text Before Start, 27, 30 208 155 25, tab 2
  text Between Questions (answered), 36, 30 342 155 25, tab 2
  text Given to Answer, 37, 30 234 155 25, tab 2
  text Before Auto-Hint, 38, 30 288 155 25, tab 2
  text (timed-out), 39, 30 369 155 25, tab 2
  text Before hint allowed, 862, 30 261 155 25, tab 2
  text Between Ping Delay, 167, 30 398 155 25, tab 2
  text Between Auto-Hints, 177, 30 315 155 25, tab 2
  edit $slag(start), 135, 192 208 65 24, tab 2
  edit $slag(answered), 145, 192 346 65 24, tab 2
  edit $slag(timedout), 155, 192 234 65 24, tab 2
  edit $slag(hint), 165, 192 290 65 24, tab 2
  edit $slag(timed), 175, 192 374 65 24, tab 2
  edit $slag(hintallow), 185, 192 262 65 24, tab 2
  edit $slag(ping), 195, 192 402 65 28, tab 2
  edit $slag(betweenhint), 205, 192 318 65 24, tab 2
  box Questions, 64, 14 40 262 144, tab 2
  text Default Round, 68, 120 54 78 17, tab 2
  text Champ Goal, 69, 284 380 94 21, tab 2
  text Team Round, 71, 120 102 70 17, tab 2
  edit $triv(default), 299, 148 74 91 24, tab 2
  edit $triv(reset), 215, 384 380 79 28, tab 2
  edit $triv(dteam), 217, 164 122 71 24, tab 2
  button $record.type($triv(Record)), 218, 82 150 149 20, tab 2
  button Themes, 700, 374 304 68 20, tab 2
  radio Unlimited, 201, 24 82 96 20, tab 2
  radio Team, 202, 24 104 92 20, tab 2
  radio Normal, 203, 24 60 84 20, tab 2
  check Disable, 816, 284 300 80 20, tab 2
  box , 8, 278 284 186 56, tab 2
  check "Background", 158, 600 48 92 24, tab 2 push
  check Champ Mode, 42, 284 356 136 21, tab 2
  box , 179, 278 344 188 68, tab 2
  box Score By, 178, 280 200 184 84, tab 2
  check "Change", 182, 288 224 84 20, tab 2
  combo 183, 288 248 128 100, tab 2 size drop
  tab Teams, 3
  box Names, 72, 12 80 872 140, tab 3
  text Team 1, 73, 28 112 60 20, tab 3
  text Team 2, 74, 28 152 60 20, tab 3
  text Team 3, 308, 396 112 60 20, disable tab 3
  text Team 4, 309, 396 152 60 20, disable tab 3
  box Victories, 75, 20 220 868 220, tab 3
  text Tied Message, 76, 32 256 66 20, tab 3
  text Team 1 Wins, 77, 32 285 66 20, tab 3
  text Team 2 Wins, 78, 32 314 66 20, tab 3
  text Team 3 Wins, 303, 32 343 66 20, disable tab 3
  text Team 4 Wins, 304, 32 372 66 20, disable tab 3
  edit $te(1), 380, 92 112 280 27, tab 3 autohs
  edit $te(2), 381, 92 152 280 27, tab 3 autohs
  edit $te(4), 382, 468 152 280 27, disable tab 3 autohs
  edit $te(3), 383, 468 112 280 27, disable tab 3 autohs
  edit $te(0).victory, 320, 96 256 770 25, tab 3 autohs
  edit $te(1).victory, 321, 96 285 770 25, tab 3 autohs
  edit $te(2).victory, 322, 96 314 770 25, tab 3 autohs
  edit $te(3).victory, 323, 96 343 770 25, disable tab 3 autohs
  edit $te(4).victory, 324, 96 372 770 25, disable tab 3 autohs
  check Limit Join Period, 330, 284 52 152 27, tab 3 push
  edit $te(JoinBefore), 335, 440 51 112 27, tab 3
  radio 2 Teams, 28, 48 48 92 20, tab 3
  radio 4 Teams, 29, 152 52 84 20, tab 3
  tab Awards, 4
  box Awards, 79, 14 56 872 220, tab 4
  button Delete, 411, 828 236 52 20, tab 4
  button Add, 412, 828 84 52 20, tab 4
  list 420, 19 72 800 190, tab 4 size
  text "* is winner's nick.", 81, 398 425 144 25, tab 4
  text "^ is value of trigger", 82, 554 425 156 25, tab 4
  check Disable, 819, 20 36 84 21, tab 4
  combo 137, 94 296 144 100, tab 4 size drop
  edit "", 139, 432 300 68 25, tab 4
  text "Award", 140, 26 392 62 24, tab 4
  edit "", 142, 92 388 712 33, tab 4 autohs
  text "Trigger on", 154, 32 296 58 24, tab 4
  combo 159, 314 300 108 100, tab 4 size drop
  text "and", 160, 518 300 30 20, hide tab 4
  edit "", 161, 556 300 68 25, hide tab 4
  text "points", 162, 480 324 46 20, tab 4
  text "Do Action", 163, 36 348 50 24, tab 4
  text "values", 164, 264 300 42 24, tab 4
  combo 166, 90 348 144 120, tab 4 size drop
  tab Status, 5
  text Trivia Script version:, 84, 24 48 150 20, tab 5
  text $strip($msg.trivia.version), 85, 184 48 150 20, tab 5
  text Trivia bot is currently:, 86, 24 70 150 20, tab 5
  text $trivon, 504, 184 70 80 20, tab 5
  text Current mIRC version is:, 87, 24 92 150 20, tab 5
  text $version, 90, 184 92 80 20, tab 5
  text Current Trivia directory exists:, 91, 24 114 150 20, tab 5
  text $trivia.dir, 92, 184 114 80 20, tab 5
  text Currently in Trivia Channel:, 93, 24 136 150 20, tab 5
  text $trivia.chan, 94, 184 136 80 20, tab 5
  text Question file in Directory:, 95, 24 158 150 20, tab 5
  text $trivia.file, 98, 184 158 80 20, tab 5
  text Number of questions:, 103, 24 180 150 20, tab 5
  text $numl, 104, 184 180 78 20, tab 5
  button Delete Scores, 515, 280 104 128 20, tab 5
  button Scores, 519, 280 76 124 20, tab 5
  list 601, 26 210 284 114, tab 5 sort size
  button Unban, 602, 314 296 80 20, tab 5
  button Ban, 603, 314 218 80 20, tab 5
  list 610, 18 336 292 154, tab 5 sort size
  button Add Friend, 611, 314 342 80 20, tab 5
  button Remove, 612, 318 468 80 20, tab 5
  tab Commands, 7
  box Command Limits, 105, 288 184 300 48, tab 7
  combo 806, 300 200 276 132, disable tab 7 size drop
  text Command Prefix, 107, 28 456 82 20, tab 7
  edit %command-prefix, 850, 112 452 88 29, tab 7
  text blank = default, 109, 32 484 170 24, tab 7
  button "Build HTML Options", 157, 304 476 207 25, tab 7
  list 800, 20 60 256 356, tab 7 size
  text "Commands", 170, 20 40 102 16, tab 7
  combo 809, 300 248 276 100, disable tab 7 size drop
  box "Respond Method", 168, 288 232 300 48, tab 7
  check "Disable", 801, 296 80 92 24, tab 7
  text "Name", 172, 292 112 42 20, tab 7
  edit "", 803, 344 112 236 21, tab 7 read
  edit "", 802, 288 132 296 49, tab 7 read autovs
  box "Default Respond Method", 180, 284 348 304 72, tab 7
  combo 181, 300 364 280 136, tab 7 size drop
  box "Command Attributes", 176, 284 56 308 292, tab 7
  button Cancel, 101, 618 486 52 20, cancel
  button OK, 100, 673 486 52 20, ok
  button Apply, 102, 560 486 48 20
  link $nopath($trivia.web), 518, 560 460 160 20
}
;########################################################
;# DIALOG EVENTS.                                       #
;########################################################
on *:dialog:trivset:init:*:{
  var %i = 1
  while ($getset(chan, %i)) {
    did -a $dname 108 $gettok($getset(chan, %i), 1, 59)
    inc %i
  }
  if ($did(108,1)) { did -c $dname 108 1 }
  var %i = $numtok($status.toks, $asc(.))
  while (%i >= 1) {
    if ($getset(status, $gettok($status.toks, %i, $asc(.))) == 1) { did -c $dname $calc(39 + %i) }
    dec %i
  }
  if (!$did(58).state) {
    if (!$getset(status, plot)) { did -c $dname 130 }
    else { did -c $dname 129 }
  }
  if ($getset(trivia,ranks) == 1) { did -c $dname 148 }
  if ($getset(status,naoff) == 1) { did -c $dname 88 }
  if ($getset(status,hintpause) == 1) { did -c $dname 96 }
  if ($getset(status,autostart) == 1) { did -c $dname 49 }
  if ($getset(status,monday) == 1) { did -c $dname 126 }
  if ($getset(status,noautoqm) == 1) { did -c $dname 830 }
  if ($getset(status,noawards) == 1) { did -c $dname 819 }
  if ($getset(status,nospellfix) == 1) { did -c $dname 817 }
  if ($getset(status,sayhintnum) == 1) { did -c $dname 147 }
  if ($getset(status,keepask) == 1) { did -c $dname 156 }
  if ($getset(status,shownone) == 1) { did -c $dname 143 }
  did -c $dname $calc(149 + $getset(trivia,firsthint))
  if ($getset(hide,score) == 1) { did -c $dname 106 }
  if ($getset(hide,time) == 1) { did -c $dname 169 }
  if ($getset(hide,streak) == 1) { did -c $dname 171 }
  if ($getset(hide,wpm) == 1) { did -c $dname 173 }
  if ($getset(color,on) == 1) { did -c $dname 116 }
  if ($getset(color,bon) == 1) { did -c $dname 158 }
  if ($getset(color,1-bold) == 1) { did -c $dname 117 }
  if ($getset(color,1-underline) == 1) { did -c $dname 118 }
  if ($getset(color,2-bold) == 1) { did -c $dname 127 }
  if ($getset(color,2-underline) == 1) { did -c $dname 128 }
  if ($getset(trivia,odefault) == Unlimited) { did -c $dname 201 }
  elseif ($getset(trivia,odefault) == Team) { did -c $dname 202 }
  else { did -c $dname 203 }
  if ($getset(team,Joinbeforeon) == 1) { did -c $dname 330 }
  if ($getset(team,4-team) == 1) {
    trivset.teams 1
    did -c $dname 29
  }
  else { did -c $dname 28 }
  var %i = 0
  while (%i <= 16) {
    did -a $dname 111,112,113,114 $colorcode(%i)
    inc %i
  }
  did -a $dname 806 Default
  did -a $dname 806 User
  did -a $dname 806 Voice
  did -a $dname 806 Half-Op
  did -a $dname 806 Op
  did -a $dname 806 Friend
  did -a $dname 806 Nobody
  did -c $dname 806 1
  did -a $dname 183 Day
  did -a $dname 183 Week
  did -a $dname 183 Month
  did -a $dname 183 Year
  did -a $dname 183 Total
  did -c $dname 183 $ifd($getset(status,scoreby),5)
  did -a $dname 181,809 Default
  did -a $dname 181,809 Notice
  did -a $dname 181,809 MSG Channel
  did -a $dname 181,809 MSG User
  did -a $dname 181,809 Describe Channel
  did -c $dname 181 $ifd($getset(status,respondlevel),1)
  did -c $dname 809 1
  did -c $dname 111 $calc($did(121) + 1)
  did -c $dname 112 $calc($did(122) + 1)
  did -c $dname 113 $calc($did(123) + 1)
  did -c $dname 114 $calc($did(124) + 1)
  awards.load
  var %i = 1
  while ($setini(banned,%i)) {
    did -a $dname 601 $getset(banned,%i)
    inc %i
  }
  did -a $dname 961 $iif($chr($triv(ch)),$chr($triv(ch)),_)
  disable.load
  trivia.load.friends
  check.toggle.multichan
  check.toggle.options
  check.color.toggle
  check.awards.toggle
  multichan.load
}
on *:dialog:trivset:sclick:100,102:{
  setset trivia delimiter $did(31)
  setset trivia additions $did(32)
  setset trivia report $did(33)
  setset trivia dir $did(35)
  setset trivia translate $did(131)
  setset status plot $did(129).state
  setset status naoff $did(88).state
  setset status monday $did(126).state
  setset status noautoqm $did(830).state
  setset status noawards $did(819).state
  setset status nospellfix $did(817).state
  setset status sayhintnum $did(147).state
  setset status keepask $did(156).state
  setset status shownone $did(143).state
  setset hide score $did(106).state
  setset hide time $did(169).state
  setset hide streak $did(171).state
  setset hide wpm $did(173).state
  setset trivia naoff $did(89)
  setset status hintpause $did(96).state
  setset trivia hintpause $did(97)
  setset trivia limitguess $did(144)
  setset trivia perchint $did(99)
  setset trivia numhint $did(861)
  setset trivia DPH $did(863)
  setset trivia PPQ $did(65)
  var %i = 0
  while (%i < 4) {
    if ($did($calc(149 + %i)).state == 1) setset trivia firsthint %i
    inc %i
  }
  setset trivia ranks $did(148).state
  setset color on $did(116).state
  setset color bon $did(158).state
  setset color 1-bold $did(117).state
  setset color 1-underline $did(118).state
  setset color 2-bold $did(127).state
  setset color 2-underline $did(128).state
  setset team JoinBeforeon $did(330).state
  setset team Joinbefore $did(335)
  setset color 1 $int($did(121))
  setset color 2 $int($did(122))
  setset color 3 $int($did(123))
  setset color 4 $int($did(124))
  varcolors
  var %i = 1
  while (%i <= 8) {
    setset lag $gettok(start.answered.timedout.hint.timed.hintallow.ping.betweenhint, %i, $asc(.)) $int($did($calc(125 + (%i * 10))))
    inc %i
  }
  var %i = $numtok($status.toks, $asc(.))
  while (%i >= 1) {
    setset status $gettok($status.toks, %i, $asc(.)) $did($calc(39 + %i)).state
    dec %i
  }
  setset trivia onjoin $did(138)
  setset trivia default $int($did(299))
  setset trivia odefault
  if ($did(201).state == 1) { setset trivia odefault Unlimited }
  if ($did(202).state == 1) { setset trivia odefault Team }
  setset trivia reset $int($did(215))
  setset trivia dteam $int($did(217))
  setset award
  var %i = 1
  while (%i <= $did(420).lines) {
    setset award %i $did(420,%i)
    inc %i
  }
  setset team 1 $did(380)
  setset team 2 $did(381)
  setset team 3 $did(382)
  setset team 4 $did(383)
  setset team 0victory $did(320)
  setset team 1victory $did(321)
  setset team 2victory $did(322)
  setset team 3victory $did(323)
  setset team 4victory $did(324)
  setset team 4-team $did(29).state
  var %i = 1
  setset trivia ch $asc($right($did(961),1))
  %command-prefix = $did(850)
  disable.save
  setset status respondlevel $did(181).sel
  setset status scoreby $did(183).sel
}
on *:dialog:trivset:sclick:816:{
  setset disable 18.disable $did($did).state
  check.toggle.options
} 
on *:dialog:trivset:sclick:12:{
  if ((!$did(34).sel) || (!$did(108).sel)) { return }
  var %todel = $did(34).sel
  did -d $dname 34 %todel
  did -c $dname 34 %todel
  save.qs
}
on *:dialog:trivset:sclick:24:{
  var %temp.file = $$sfile($iif($isdir($did(35)),$did(35),$mircdir))
  did -a $dname 34 $nopath(%temp.file)
  did -ra $dname 35 $nofile(%temp.file)
  save.qs
}
on *:dialog:trivset:edit:30:{
  var %temp.num = $did(108).sel
  tchan.set $did(108).sel 1 $did(30)
  did -o $dname 108 $did(108).sel $did(30)
  did -c $dname 108 %temp.num
}
on *:dialog:trivset:sclick:108:{ multichan.load }
on *:dialog:trivset:sclick:115:{ 
  var %toadd = $$?="Add what channel?"
  did -a $dname 108 %toadd
  chan.add %toadd
}
on *:dialog:trivset:sclick:119:{
  var %todel = $did(108).sel
  chan.del %todel
  did -d $dname 108 %todel
  did -c $dname 108 %todel
  did -r $dname 30,34,132
  multichan.load
  check.toggle.multichan
}
on *:dialog:trivset:sclick:136:{
  var %temp.file = $$sfile(" $+ $mircdir $+ \ $+ *.txt $+ ", Choose a trivia translation file.)
  did -ra $dname 131 $nopath(%temp.file)
}
on *:dialog:trivset:sclick:13:{
  var %temp.file = $$sdir($mircdir, Choose a trivia directory.)
  echo -s .... %temp.file
  did -ra $dname 35 %temp.file
}
on *:dialog:trivset:edit:132:{ tchan.set $$did(108).sel 4 $$did(132) }
on *:dialog:trivset:edit:67:{ tchan.set $$did(108).sel 2 $$did(67) }
on *:dialog:trivset:edit:544:{ tchan.set $$did(108).sel 3 $$did(544) }
on *:dialog:trivset:sclick:141:{
  did -ra $dname 132 $nopath($$sfile(" $+ $mircdir $+ \ $+ *.fil $+ ",Choose a scores file.))
  tchan.set $$did(108).sel 4 $did(132)
}
;########################################################
;# MOUSE EVENTS.                                        #
;########################################################
on *:dialog:trivset:mouse:40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,88,96,106,126,143,156,169,171,173,817,830:{ 
  if (%didt == $did) { return }
  if ($did == 43) { exp Forbids any partial matches, for example if the answer is "truck" and you guess "not a truck" it won't take the answer. }
  if ($did == 44) { exp Disables the decheater feature, which might produce blocks between words or odd characters on some fonts. Prevents people from using some cheating scripts. }
  if ($did == 50) { exp Disables bonus. For example if a question is "2004: This picture won movie of the year-" the bot would take this question to be worth 2004 points. }
  if ($did == 54) { exp If the room is empty the bot turns off. }
  if ($did == 61) { exp Turns off the color shortening. Color shortening is a feature which reduces the amount of text sent by optimizing the colorcodes. }
  if ($did == 62) { exp Turns off categories. If categories exist in a question file #Category after a list of questions, it doesn't look for or display it. }
  if ($did == 106) { exp Hide score. Refuses to indicate how many more points any person has. }
  if ($did == 169) { exp Hide time. Refuses to indicate how long it took for any person to answer. }
  if ($did == 171) { exp Hide streak. Refuses to indicate the current or record streak. }
  if ($did == 173) { exp Hide WPM. Refuses to indicate the Words Per Minute people achieve. }
  if ($did == 40) { exp Echo's the answer so that you can see it after the question is read. }
  if ($did == 60) { exp Uses the American dating style for the $pre $+ stats response. MM/DD/YY rather than DD/MM/YY. }
  if ($did == 63) { exp Stops showing the number before the question in the question message. }
  if ($did == 48) { exp Traditional win provides more less clinical information about the correct answer. }
  if ($did == 56) { exp Provides the spacing of the answer directly after the question is read. }
  if ($did == 46) { exp Gives a message to each person who joins the trivia channel, providing information about the bot. * = nick,  $chr(35) = channel, @ = rank, ^ = score. eg: Welcome to #, * trivia bot is active... "!trivia" to start a game. Blank uses default. }
  if ($did == 53) { exp For scramble questions, this forces the standard scramble category to read Unscramble the Following. }
  if ($did == 57) { exp Rather than accept answers anywhere in a response, this feature forces the bot to ignore answered contained entirely inside a response. }
  if ($did == 49) { exp This feature makes the bot start up as soon as you rejoin the trivia channel. }
  if ($did == 42) { exp This allows for champ mode, when a specific score is reached the game resets the score and logs the winner. }
  if ($did == 58) { exp Rather than start the hint from left to right it displays random letters in the hint. }
  if ($did == 41) { exp This feature automaticly displays a hint to the channel after a time specified in Defaults. }
  if ($did == 45) { exp This allows people to be told the correct answer after nobody in the room answered correctly. }
  if ($did == 55) { exp When a team game is ends this provides a list of players on each team. }
  if ($did == 59) { exp By default the bot displays the first answer in the answer file as correct. But, with this enabled the matched answer is displayed. }
  if ($did == 88) { exp After a specified number of questions, the bot will turn itself off. }
  if ($did == 96) { exp After a hint is requested this feature blocks the correct answer from being accepted from that person for a given amount of time. }
  if ($did == 47) { exp This allows for unfinished part of a hint to use a specific character to indicate where letters are missing. }
  if ($did == 51) { exp This option limits the number of guesses to the specific value. }
  if ($did == 52) { exp This option makes a round hall of fame displayed along with the win messages throughout a trivia round. }
  if ($did == 156) { exp This feature retains the hash table that scores the asked questions beyond one round of trivia. Make repeats happen less often. }
  if ($did == 143) { exp After a win, this feature would will turn off any acknowledgement of the answer to the room. Protect questions. }
  if ($did == 126) { exp In the United States and other countries the week starts on Sunday, this is default. This feature starts the week mark a day later. }
  if ($did == 817) { exp Turns off the spell correction and only allows exact answers to be accepted. }
  if ($did == 830) { exp Turns off the automatic ? at the end of each question. A - at the end of the question also does this. }
  set -u5 %didt $did 
}
alias exp { did -ra $dname 22 $$1- }
;########################################################
;# Stray.                                               #
;########################################################
on *:dialog:trivset:sclick:20:{ if (!$dialog(trivrank)) dialog -m trivrank trivrank } 
on *:dialog:trivset:sclick:28,29:{ trivset.teams $iif($did != 28,1) }
alias hint.example { return This is an example of a hint }
on *:dialog:trivset:sclick:58,129,130:{
  if ($did == 58) { did -ra $dname 199 $scatter(50,$hint.example) }
  else if ($did == 129) { did -ra $dname 199 $plot(50,$hint.example) }
  else { did -ra $dname 199 $standard(50,$hint.example) }
}
on *:dialog:trivset:sclick:111,112,113,114:{ did -ra $dname $calc($did + 10) $calc($did($did).sel - 1) }
on *:dialog:trivset:sclick:218:{
  var %record = $calc($triv(Record) + 1)
  if (%record == 9) { var %record = 1 }
  did -ra $dname $did $record.type(%record)
  setset Trivia Record %record
}
;########################################################
;# Awards.                                              #
;########################################################
on *:dialog:trivset:sclick:412:{ 
  did -a $dname 420 0 0 0 0 0 Award
  did -c $dname 420 $did(420).lines
  check.award.click
}
on *:dialog:trivset:sclick:411:{ did -d $dname 420 $$did(420,1).sel | check.awards.toggle }
on *:dialog:trivset:sclick:420:{ check.award.click }
alias check.award.click {
  check.awards.toggle
  tokenize 32 $$did(420).seltext
  did -c $dname 137 $calc($1 + 1)
  did -c $dname 159 $calc($2 + 1)
  did -c $dname 166 $calc($3 + 1)
  did -ra $dname 139 $4
  did -ra $dname 161 $5
  did -ra $dname 142 $6-
  check.award.range
}
alias check.award.range {
  did $iif((($did(159).seltext == Between) || ($did(159).seltext == Random)),-v,-h) $dname 160,161
}
on *:dialog:trivset:sclick:137,159,166:{ award.modified }
on *:dialog:trivset:edit:139,142,161:{ award.modified }
alias award.modified {
  if (!$did(420).sel) { return }
  var %t.line = $did(420).sel
  did -o $dname 420 $did(420).sel $calc($did(137).sel - 1) $calc($did(159).sel - 1) $calc($did(166).sel - 1) $did(139) $did(161) $did(142)
  did -c $dname 420 %t.line
  check.award.range
}
;########################################################
;# Settings.                                            #
;########################################################
on *:dialog:trivset:sclick:515:{
  if ($?!="Are you sure you wish to delete all scores?") {
    rename $scoresfil $asctime(yymmddhhmmss) $+ .bak
    trivia.flush
  }
}
on *:dialog:trivset:sclick:518:{ run $trivia.web }
on *:dialog:trivset:sclick:519:{ dialog -m triviascores triviascores }
on *:dialog:trivset:sclick:602:{ 
  tunban $did(601,1).sel
  did -d $dname 601 $$did(601,1).sel
}
on *:dialog:trivset:sclick:603:{ 
  var %ban = $$?"Enter the nick or address (nick!ident@host) of a person to ban, note wildcards are permitted."
  tban %ban
  did -a $dname 601 %ban
}
on *:dialog:trivset:sclick:611:{
  var %friend.add = $$?"Enter the nick or address (nick!ident@host) of a friend to add, note wildcards are permitted."
  did -a $dname 610 %friend.add
  triviafriend.add %friend.add
}
on *:dialog:trivset:sclick:612:{
  triviafriend.del $$did(610).sel
  trivia.load.friends
}
on *:dialog:trivset:sclick:700:{ if (!$dialog(triviatheme)) { dialog -m triviatheme triviatheme } }
on *:dialog:trivset:sclick:157:{ if (!$dialog(trivbuild)) { dialog -m trivbuild trivbuild } }
;########################################################
;# Disables                                             #
;########################################################
on *:dialog:trivset:sclick:800:{
  disable.access
  disable.check.disabled
}
on *:dialog:trivset:sclick:801:{
  setset disable $$did(800).sel $+ .disable $did($did).state
  did -oc $dname 800 $did(800).sel $gettok($disable.tokens,$did(800).sel,$asc(;)) $iif($getset(disable,$did(800).sel $+ .disable),( $+ Disabled $+ ))
  disable.check.disabled
}
on *:dialog:trivset:sclick:806:{ setset disable $$did(800).sel $+ .limitlevel $did($did).sel }
on *:dialog:trivset:sclick:809:{ setset disable $$did(800).sel $+ .respondlevel $did($did).sel }
alias disable.access {
  did $iif($getset(disable,$did(800).sel $+ .disable) == 1,-c,-u) trivset 801
  did -ra trivset 802 $gettok($disable.info.tokens,$did(800).sel,$asc(;))
  did -ra trivset 803 $did(800).seltext
  did -c trivset 806 $ifd($getset(disable,$did(800).sel $+ .limitlevel),1)
  did -c trivset 809 $ifd($getset(disable,$did(800).sel $+ .respondlevel),1)
}
alias disable.check.disabled { did $iif(!$did(801).state,-e,-b) $dname 802,803,806,809 }
alias disable.save { }
alias disable.load {
  did -r trivset 800
  tokenize $asc(;) $disable.tokens
  var %i = 1
  while (%i <= $0) {
    did -a trivset 800 $eval($ $+ %i,2) $iif($getset(disable,%i $+ .disable),( $+ Disabled $+ ))
    inc %i
  }
}
alias disable.tokens { return trivia N;trivia unlimited;trivia team;trivia team N;pause/resume;op;op unban;hof;hoftime;hofstreak;hofwpm;records;op find;op ask;next;answer;ping;themes;add/report;op ban;disable/enable;hint;vowels;last;words;repeat;op add;trivia;strivia;promotion;join message;help;join N;op team }
alias disable.info.tokens { return Start N question game;Start unlimited Game;Start team game;Start team game for N questions;pause/resume;operator commands;op unban;hall of fame;hoftime;hofstreak;hofwpm;records;op find;op ask;End current question early;Answer to last question;ping;themes;add/report;op ban;disable/enable;hint;vowels;last;words;repeat;op add;trivia;strivia;promotion;join channel message;general help and command specific help;join team command;op team <player> <#>, sets team assignment }
alias isdis {
  check.respond $1
  if ($getset(disable, $1 $+ .disable) == 1) { return $true }
  if (($chan) && ($nick) && (!$trivia.allowed($1))) { return $true }
}
alias -l trivia.allowed {
  var %level = $getset(disable,$$1 $+ .limitlevel)
  if ((!%level) || (%level == 1)) {
    %level = 1
    if ($1 == 6) %level = 4
  }
  if (%level == 7) { return }
  if (($is.friend) && (%level <= 6)) { return $true }
  if (($nick isop $chan) && (%level <= 5))  { return $true }
  if (($nick ishelp $chan) && (%level <= 4)) { return $true }
  if (($nick isvoice $chan) && (%level <= 3))  { return $true }
  if (($nick ison $chan) && (%level <= 2))  { return $true }
}
alias -l check.respond {
  unset %respond
  var %respondlevel = $getset(disable,$1 $+ .respondlevel)
  if (%respondlevel == 2) set -u2 %respond .notice $nick
  else if (%respondlevel == 3) set -u2 %respond msg $iden
  else if (%respondlevel == 4) set -u2 %respond .msg $nick
  else if (%respondlevel == 5) set -u2 %respond describe $iden
}
;########################################################
;# DIALOG TOGGLES                                       #
;########################################################
on *:dialog:trivset:sclick:158,116:{ check.color.toggle }
on *:dialog:trivset:sclick:88,96,51,47,42,330,819,148,46,182:{ check.toggle.options }
alias check.toggle.options {
  did $iif($did(88).state,-e,-b) $dname 89
  did $iif($did(96).state,-e,-b) $dname 97
  did $iif($did(51).state,-e,-b) $dname 144
  did $iif($did(47).state,-e,-b) $dname 961,21
  did $iif($did(42).state,-e,-b) $dname 215
  did $iif($did(330).state,-e,-b) $dname 335
  did $iif(!$did(816).state,-e,-b) $dname 700
  did $iif($did(148).state,-e,-b) $dname 20
  did $iif($did(46).state,-e,-b) $dname 138
  did $iif($did(182).state,-e,-b) $dname 183
  if (($did == 819) || (!$did)) { 
    did $iif(!$did(819).state,-e,-b) $dname 420,411,412
    did -u $dname 420
    check.awards.toggle
  }
}
alias check.awards.toggle { did $iif($did(420).sel,-e,-b) $dname 137,159,166,139,142,161,140,154,160,162,163,164,81,82 }
alias check.toggle.multichan { did $iif($did(108).sel,-e,-b) $dname 12,24,30,34,132,141,544,67 }
alias check.color.toggle {
  did $iif($did(116).state,-e,-b) $dname 23,25,120,110,121,122,123,124,117,118,127,128,111,112,113,114
  if (!$did(158).state) did -b $dname 25,123,124,113,114
}
;########################################################
;# TRIVIA SETUP, alias expanded.                        #
;########################################################
alias save.qs {
  var %i = 1
  tchan.noqs $$did(108).sel
  while (%i <= $did(34).lines) {
    tchan.set $did(108).sel $calc(4 + %i) $did(34,%i)
    inc %i
  }
}
alias status.toks { return echo.autohint.champ.exactmatch.nodecheater.showanswer.onjoin.cross.tradwin.autostart.nobonus.limitguess.rrs.sayscramble.emptyoff.noshowt.answers.nomid.scatter.showmatched.adate.nocolorshort.nocat.nosaycurrent }
alias chan.add { tchan.set $calc($setini(chan,0) + 1) 1 $1- }
alias chan.set {
  var %chan.num = $tfindchan($1)
  if (%chan.num) { tchan.set %chan.num $2 $3- }
}
alias chan.del {
  var %i = $$1, %j = $setini(chan,0)
  while (%i < %j) {
    setset chan %i $getset(chan,$calc(%i + 1))
    inc %i
  }
  setset chan %j
}
alias tchan.noqs { setset chan $1 $gettok($getset(chan, $1),1-4,59) }
alias tchan.set {
  if ($3- != $null) {
    var %nl = $getset(chan,$1)
    if (!%nl) { %nl = $1 $+ ;*;*; $+ $scoresfil $+ ; $+ questions.txt }
    if ($2 > $numtok(%nl,59)) %nl = %nl $+ $str(;0,$calc($2 - $numtok(%nl,59)))
    %nl = $puttok(%nl,$3-,$2,59)
    setset chan $1 %nl
  }
}
alias tfindchan {
  var %i = 1
  while ($tchan(%i)) {
    if (((!$1) || ($tchan(%i) == $1)) && ((!$2) || ($tchan(%i,3) iswm $2)) && ((!$3) || ($tchan(%i,2) iswm $3))) { return %i }
    inc %i
  }
}
alias multichan.load {
  if (!$did(108).sel) { return }
  did -r $dname 34
  did -ra $dname 30 $tchan($did(108).sel)
  did -ra $dname 67 $ifd($tchan($did(108).sel,2),*)
  did -ra $dname 544 $ifd($tchan($did(108).sel,3),*)
  did -ra $dname 132 $tchan($did(108).sel,4)
  var %i = 5
  while ($tchan($did(108).sel, %i)) {
    did -a $dname 34 $tchan($did(108).sel,%i)
    inc %i
  }
  check.toggle.multichan
}
alias awards.load {
  var %i = 1
  did -r $dname 420
  while ($aw(%i)) {
    did -a $dname 420 $aw(%i)
    inc %i
  }
  did -r $dname 137,159,166
  %i = 1
  while ($gettok($award.on.tok, %i, $asc(.))) {
    did -a $dname 137 $gettok($award.on.tok, %i, $asc(.))
    inc %i
  }
  %i = 1
  while ($gettok($award.val.tok, %i, $asc(.))) {
    did -a $dname 159 $gettok($award.val.tok, %i, $asc(.))
    inc %i
  } 
  %i = 1
  while ($gettok($award.do.tok, %i, $asc(.))) {
    did -a $dname 166 $gettok($award.do.tok, %i, $asc(.))
    inc %i
  }
}
alias -l record.type { return $gettok(hof.streak.time.wpm.champ.web.roundscores.records, $ifd($1, 8), $asc(.)) }
alias -l trivset.teams { did $iif($1, -e, -b) $dname 308,309,303,304,382,383,323,324 }
alias triviafriend.del {
  var %i = $$1, %j = $setini(friend,0)
  while (%i < %j) {
    setset friend %i $getset(friend,$calc(%i + 1))
    inc %i
  }
  setset friend %j
}
alias triviafriend.add {
  var %i = 1
  while ($getset(friend, %i)) { inc %i }
  setset friend %i $1- 
}
alias triviafriend.clear { setset friend }
alias trivia.load.friends {
  did -r $dname 610
  var %i = 1
  while ($getset(friend, %i)) {
    did -a $dname 610 $getset(friend, %i)
    inc %i
  }
}
;########################################################
;# TRIVIA RANKS DIALOG.                                 #
;########################################################
dialog trivrank {
  title "Trivia Ranks"
  size -1 -1 180 104
  option dbu
  list 1, 2 12 146 50, size
  text "Rank Name", 11, 4 66 31 8
  edit "", 2, 46 64 74 10, autohs
  text "Points Required", 10, 4 76 39 8
  edit "", 3, 46 76 36 10, read autohs
  button "Add", 4, 150 12 21 8
  button "Del", 5, 150 24 21 8
  button "Ok", 999, 114 78 17 8, ok
  check "Trivia Ranks", 6, 4 4 50 6
}
;########################################################
;# DIALOG EVENTS.                                       #
;########################################################
on *:dialog:trivrank:init:*:{
  if ($getset(trivia,ranks) == 1) { did -c $dname 6 }
  check.toggle.ranks
  var %i = $setini(ranks,0), %j = 1
  while (%j <= %i) {
    did -a $dname 1 $setini(ranks,%j) : $getset(ranks, $setini(ranks,%j)) 
    inc %j
  }
}
on *:dialog:trivrank:sclick:1:{
  did -ra $dname 3 $setini(ranks, $did(1).sel)
  did -ra $dname 2 $getset(ranks, $setini(ranks, $did(1).sel))
}
on *:dialog:trivrank:edit:2:{
  if (!$did(1).sel) return
  setset ranks $$did(3) $$did(2)
  var %p = $did(1).sel
  did -o $dname 1 %p $did(3) : $did(2)
  did -c $dname 1 %p
}
on *:dialog:trivrank:sclick:4:{
  var %r = $$?="What is the minimum amount points for this rank?"
  if ((%r !isnum) || ($getset(ranks,%r))) return
  var %n = $$?="What is this rank called?"
  setset ranks %r %n
  did -a $dname 1 %r : %n
}
on *:dialog:trivrank:sclick:5:{
  var %p = $$did(1).sel
  setset ranks $$setini(ranks, %p)
  did -d $dname 1 %p
  did -r $dname 2,3
}
on *:dialog:trivrank:sclick:6:{
  setset trivia ranks $did(6).state
  check.toggle.ranks
}
alias check.toggle.ranks { did $iif($did(6).state,-e,-b) $dname 1,2,3,4,5,10,11 }
;########################################################
;# TRIVIA BUILD DIALOG.                                 #
;########################################################
dialog trivbuild {
  title "Build Html"
  size -1 -1 200 232
  option dbu
  check Run FTP Batch, 1, 8 52 50 10
  edit "", 2, 10 124 86 88, autohs autovs
  button Ok, 99, 172 220 23 10, ok
  radio Write All Scores, 3, 80 12 50 10
  radio Write Top, 4, 132 12 34 10
  edit 25, 5, 168 12 20 10
  box Generate Scores File, 57, 76 4 118 35
  text Password, 54, 104 172 25 8
  box Ftp Batch Creator, 55, 100 124 84 88
  text Username, 53, 104 160 25 8
  text Ftp Site, 51, 104 136 25 8
  edit "", 6, 136 136 46 10, autohs
  text Port, 52, 104 148 25 8
  edit "", 7, 136 148 46 10, autohs
  edit "", 8, 136 160 46 10, autohs
  edit "", 9, 136 172 46 10,i autohs
  edit "triv.htm", 11, 136 196 46 10, autohs
  text Filename, 56, 104 196 23 6
  text Every, 58, 8 16 17 6
  edit "", 13, 28 16 22 10, autohs
  text Points, 14, 52 16 17 6
  button "Cancel", 12, 144 220 23 10, cancel
  text "Directory", 50, 104 184 25 8
  edit "", 16, 136 184 46 10
  check "Announce Update", 17, 8 68 54 10
  edit "", 18, 92 48 98 10, autohs
  text "URL", 20, 80 48 10 7
  text "Batch File", 21, 12 116 29 8
  check "Generate Scores File", 15, 8 36 62 10
  box "On Trigger", 10, 4 4 70 102
  box "Announce Update", 19, 76 40 118 22
  check "Copy File", 22, 8 84 58 10
  box "Copy File", 23, 76 64 118 42
  edit "", 24, 100 72 90 10, autohs
  button "File", 25, 80 72 17 8
  button "Dir", 26, 80 92 17 8
  edit "", 27, 100 92 90 10, autohs
  text "TO", 28, 124 84 9 7
  box "Run FTP Batch", 29, 4 108 190 110
  edit "", 30, 116 24 74 10
  text "Generate File", 31, 80 24 33 8
}
;########################################################
;# TRIVIA BUILD EVENTS.                                 #
;########################################################
on *:dialog:trivbuild:sclick:1,17,22,15,4,3:{ trivbuild.toggle.check }
on *:dialog:trivbuild:edit:13:{ trivbuild.toggle.check }
on *:dialog:trivbuild:edit:6,7,8,9,16,11:{ build.generate }
on *:dialog:trivbuild:sclick:25:{ did -ra $dname 24 $$sfile($mircdir) }
on *:dialog:trivbuild:sclick:26:{ did -ra $dname 27 $$sdir($mircdir) }
alias trivbuild.toggle.check {
  did -b $dname 1,17,15,22,4,3,5,30,18,24,27,6,7,8,9,16,2,11
  if (!$did(13)) { return }
  did -e $dname 1,17,22,15
  if ($did(1).state) {
    did -e $dname 2,6,7,8,9,16,11
    build.generate
  }
  if ($did(17).state) did -e $dname 17,18
  if ($did(22).state) did -e $dname 24,27
  if ($did(15).state) did -e $dname 3,4,30
  if ($did(4).state) did -e $dname 5
}
on *:dialog:trivbuild:init:*:{
  if ($getset(build,auto)) { did -c $dname 1 }
  if ($getset(build,web)) { did -c $dname 17 }
  if ($getset(build,copy)) { did -c $dname 22 }
  if ($getset(build,generate)) { did -c $dname 15 }
  did -c $dname $iif($getset(build,top),4,3)
  did -ra $dname 5 $getset(build,top)
  did -ra $dname 13 $getset(build,instabuild)
  did -ra $dname 18 $getset(build,web)
  did -ra $dname 30 $getset(build,genname)
  did -ra $dname 24 $getset(build,from)
  did -ra $dname 27 $getset(build,to)
  if ($getset(build,host)) { did -ra $dname 6 $getset(build,host) }
  if ($getset(build,port)) { did -ra $dname 7 $getset(build,port) }
  if ($getset(build,user)) { did -ra $dname 8 $getset(build,user) }
  if ($getset(build,pass)) { did -ra $dname 9 $decode($getset(build,pass),m) }
  if ($getset(build,dir)) { did -ra $dname 16 $getset(build,dir) }
  if ($getset(build,file)) { did -ra $dname 11 $getset(build,file) }
  build.generate
  trivbuild.toggle.check
}
on *:dialog:trivbuild:sclick:99:{ 
  setset build instabuild $did(13)
  setset build auto $did(1).state
  setset build generate $did(15).state
  setset build genname $did(30)
  setset build copy $did(22).state
  setset build web $iif($did(17).state, $did(18))
  setset build from $did(24)
  setset build to $did(27)
  setset build host $did(6)
  setset build port $did(7)
  setset build user $did(8)
  setset build pass $encode($did(9),m)
  setset build dir $did(16)
  setset build file $did(11)
  setset build top $iif($did(4).state,$did(5))
  setset build html $did(11)
  build.generate
  if ($did(2)) { filter -ifc $dname 2 $+(",$triv(dir),\,ftpbatch.txt,") * }
}
alias build.generate {
  did -r $dname 2
  did -i $dname 2 $did(2).lines open
  did -i $dname 2 $did(2).lines $did(6) $did(7)
  did -i $dname 2 $did(2).lines $did(8)
  did -i $dname 2 $did(2).lines $did(9)
  if ($did(16)) { did -i $dname 2 $did(2).lines cd $did(16) }
  did -i $dname 2 $did(2).lines put $shortfn($mircdir $+ $did(11))
  did -i $dname 2 $did(2).lines bye
}
;########################################################
;# TRIVIA THEMES DIALOG.                                #
;########################################################
dialog triviatheme {
  title "Trivia Themes"
  size -1 -1 508 340
  option pixels
  list 1, 22 24 376 88, sort size
  button Add, 2, 410 28 50 20
  button Remove, 3, 410 62 50 20
  text Name:, 30, 242 142 60 16
  text Points per Question:, 33, 238 224 100 16
  text Hint-Point Decrease:, 34, 238 250 100 16
  edit , 11, 318 142 152 20, autohs
  edit , 12, 318 168 156 20, autohs
  edit , 13, 350 194 40 20, autohs
  edit , 14, 350 224 40 20, autohs
  edit , 15, 350 250 40 20, autohs
  check Team Game, 16, 402 254 72 20, push
  check Limit Guesses, 17, 402 224 72 20, push
  check Roundscores, 18, 402 196 72 20, push
  box Lag, 35, 8 124 220 208
  text Before Start, 26, 18 150 96 20
  text Between Questions (Answered), 37, 18 180 96 28
  text Given to Answer, 38, 18 214 96 20
  text Before Auto-Hint, 39, 18 244 88 20
  text Between Question (Timed Out), 40, 18 274 88 28
  edit , 19, 140 150 80 20
  edit , 20, 140 180 80 20
  edit , 21, 140 210 80 20
  edit , 22, 140 240 80 20
  edit , 23, 140 274 80 20
  edit , 24, 140 304 80 20
  button OK, 999, 430 310 40 20, ok
  text "Before hint allowed", 5, 16 308 102 16
  box "Themes", 6, 8 8 480 116
  box "Theme Features", 7, 232 124 256 160
  button "Question File", 8, 240 168 67 17
  text "Number of Questions", 4, 240 196 102 16
}
;########################################################
;# TRIVIA THEMES EVENTS.                                #
;########################################################
on *:dialog:triviatheme:init:*:{
  var %i = 1
  while ($getset(triviamode $+ %i, name)) {
    did -a triviatheme 1 $+($getset(triviamode $+ %i, name),;,$getset(triviamode $+ %i, file),;,$getset(triviamode $+ %i, max),;,$getset(triviamode $+ %i, PPQ),;,$getset(triviamode $+ %i, DPH),;,$getset(triviamode $+ %i, team),;,$getset(triviamode $+ %i, guess),;,$getset(triviamode $+ %i, rrs),;,$getset(triviamode $+ %i, lagstart),;,$getset(triviamode $+ %i, laganswered),;,$getset(triviamode $+ %i, lagtimedout),;,$getset(triviamode $+ %i, laghint),;,$getset(triviamode $+ %i, lagtimed),;,$getset(triviamode $+ %i, laghintallow))
    inc %i
  }
}
on *:dialog:triviatheme:sclick:1:{
  did -ra triviatheme 11 $gettok($did(1).seltext, 1, $asc(;))
  did -ra triviatheme 12 $gettok($did(1).seltext, 2, $asc(;))
  did -ra triviatheme 13 $gettok($did(1).seltext, 3, $asc(;))
  did -ra triviatheme 14 $gettok($did(1).seltext, 4, $asc(;))
  did -ra triviatheme 15 $gettok($did(1).seltext, 5, $asc(;))
  did -u triviatheme 16,17,18
  if ($gettok($did(1).seltext, 6, $asc(;))) { did -c triviatheme 16 }
  if ($gettok($did(1).seltext, 7, $asc(;))) { did -c triviatheme 17 }
  if ($gettok($did(1).seltext, 8, $asc(;))) { did -c triviatheme 18 }
  did -ra triviatheme 19 $ifd($gettok($did(1).seltext, 9, $asc(;)),$slag(start))
  did -ra triviatheme 20 $ifd($gettok($did(1).seltext, 10, $asc(;)),$slag(answered))
  did -ra triviatheme 21 $ifd($gettok($did(1).seltext, 11, $asc(;)),$slag(timedout))
  did -ra triviatheme 22 $ifd($gettok($did(1).seltext, 12, $asc(;)),$slag(hint))
  did -ra triviatheme 23 $ifd($gettok($did(1).seltext, 13, $asc(;)),$slag(timed))
  did -ra triviatheme 24 $ifd($gettok($did(1).seltext, 14, $asc(;)),$slag(hintallow))
}
on *:dialog:triviatheme:sclick:2:{
  did -a triviatheme 1 $+(Themename,;,questions.txt,;,10,;,1,;,0,;,0,;,0,;,0,;,$slag(start),;,$slag(answered),;,$slag(timedout),;,$slag(hint),;,$slag(timed),;,$slag(hintallow))
  triviatheme.save
}
on *:dialog:triviatheme:sclick:3:{
  did -d triviatheme 1 $did(1).sel
  triviatheme.save
}
on *:dialog:triviatheme:sclick:8:{
  did -ra $dname 12 $nopath($$sfile(" $+ $mircdir $+ *.txt $+ ",Choose a question file.))
  triviatheme.update
}
on *:dialog:triviatheme:edit:11,12,13,14,15,19,20,21,22,23,24:{ triviatheme.update }
on *:dialog:triviatheme:sclick:16,17,18:{ triviatheme.update }
on *:dialog:triviatheme:sclick:999:{ triviatheme.save }
alias triviatheme.update { if ($did(1).sel) { did -oc triviatheme 1 $did(1).sel $+($did(11),;,$did(12),;,$did(13),;,$did(14),;,$did(15),;,$did(16).state,;,$did(17).state,;,$did(18).state,;,$did(19),;,$did(20),;,$did(21),;,$did(22),;,$did(23),;,$did(14)) } }
alias triviatheme.save {
  var %i = 1
  while ($getset(triviamode $+ %i,name)) {
    setset triviamode $+ %i
    inc %i
  }
  %i = 1
  while ($did(1,%i).text) {
    setset triviamode $+ %i name $gettok($did(1, %i).text,1,59)
    setset triviamode $+ %i file $gettok($did(1, %i).text,2,59)
    setset triviamode $+ %i max $gettok($did(1, %i).text,3,59)
    setset triviamode $+ %i ppq $gettok($did(1, %i).text,4,59)
    setset triviamode $+ %i dph $gettok($did(1, %i).text,5,59)
    setset triviamode $+ %i team $gettok($did(1, %i).text,6,59)
    setset triviamode $+ %i guess $gettok($did(1, %i).text,7,59)
    setset triviamode $+ %i rrs $gettok($did(1, %i).text,8,59)
    setset triviamode $+ %i lagstart $gettok($did(1, %i).text,9,59)
    setset triviamode $+ %i laganswered $gettok($did(1, %i).text,10,59)
    setset triviamode $+ %i lagtimedout $gettok($did(1, %i).text,11,59)
    setset triviamode $+ %i laghint $gettok($did(1, %i).text,12,59)
    setset triviamode $+ %i lagtimed $gettok($did(1, %i).text,13,59)
    setset triviamode $+ %i laghintallow $gettok($did(1, %i).text,14,59)
    inc %i
  }
}
;########################################################
;# TRIVIA SCORES DIALOG.                                #
;########################################################
dialog triviascores {
  title "Trivia Scores"
  size -1 -1 452 288
  option pixels
  list 1, 5 20 100 200, size vsbar
  list 2, 115 20 75 200, size vsbar
  list 3, 200 20 75 200, size vsbar
  list 4, 285 20 75 200, size vsbar
  list 5, 370 20 75 200, size vsbar
  button Delete, 10, 5 225 75 20
  button Reset Score, 11, 115 225 75 20
  button Reset Streak, 12, 200 225 75 20
  button Reset Time, 13, 285 225 75 20
  button Reset WPM, 14, 370 225 75 20
  button Name, 20, 5 5 50 15
  button Score, 21, 115 5 50 15
  button Streak, 22, 200 5 50 15
  button Time, 23, 285 5 50 15
  button WPM, 24, 370 5 50 15
  button Ok, 100, 398 258 45 20, ok
}
;########################################################
;# TRIVIA SCORES EVENTS.                                #
;########################################################
on 1:dialog:triviascores:init:*: { sortscores score }
alias -l sortscores {
  sort $1
  loaddata.triviascores
}
alias -l loaddata.triviascores {
  did -r $dname 1,2,3,4,5
  var %i = 1
  while ($hof(%i,1) != $null) {
    did -a $dname 1 $hof(%i,1)
    did -a $dname 2 $hof(%i,2)
    did -a $dname 3 $hof(%i,4)
    did -a $dname 4 $hof(%i,3)
    did -a $dname 5 $hof(%i,5)
    inc %i
  }
}
on 1:dialog:triviascores:sclick:1,2,3,4,5:{ did -c $dname 1,2,3,4,5 $did($did).sel }
on 1:dialog:triviascores:sclick:20,21,22,23,24: { sortscores $gettok(name.score.streak.time.wpm, $calc($did - 19), $asc(.)) }
on 1:dialog:triviascores:sclick:10: {
  deleteplayer $did(1).seltext
  if ($did(1).sel) { did -d triviascores 1,2,3,4,5 $did(1).sel }
}
on 1:dialog:triviascores:sclick:11,12,13,14: {
  setvar $did(1).seltext $gettok(score.streak.time.wpm, $calc($did - 10), 46) $iif($did == 13, 9999, 0)
  if ($did(1).sel) { did -o triviascores $calc($did - 9) $did(1).sel 0 }
}
