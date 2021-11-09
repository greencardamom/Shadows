#!/usr/bin/gawk -bE

# shadows - add {{ShadowsCommons}} to File: pages
#
# Source: https://github.com/greencardamom/Shadows
# Info  : https://en.wikipedia.org/wiki/User:GreenC_bot/Job_10

# The MIT License (MIT)
#
# Copyright (c) February 2019-2021
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Dependency:
#  https://github.com/greencardamom/BotWikiAwk

BEGIN {
  BotName = "shadows"
}

@include "botwiki.awk"
@include "library.awk"

BEGIN {

  Version = "1.50"

  IGNORECASE = 1

  debug = 0    # 1 = debug, 0 = production

  Email = "youremail@mail.com"
  Exe["mailx"] = "/usr/bin/mailx"
  Exe["mysql"] = "/usr/bin/mysql"
  Exe["shadows.py"] = Home "shadows.py"

  G["log"] = Home "log/"
  G["my.cnf"] = "/data/project/myproj/replica.my.cnf"  # .cnf file on toolforge
  G["shadows.sql"] = Home "shadows.sql"
  G["apiURLenwiki"]  = "https://en.wikipedia.org/w/api.php?"
  G["apiURLcommons"] = "https://commons.wikimedia.org/w/api.php?"
 
  if(debug)
    LogError = "/dev/stdout"
  else
    LogError = G["log"] "syslog"

  print "Bot ran on " curtime() " ----   ---- " >> LogError

  BotMsg = " |bot='User:GreenC bot' (shadows bot)"
  Sum = "Add {{[[Template:ShadowsCommons|ShadowsCommons]]}} (via [[User:GreenC bot/Job 10|shadows bot]])"

  load_discovered()

  main()

}

function main(  fp,i,a,SQL,k) {

  if(debug) {
    # fp = readfile(Home "example-out.tab")
    fp = readfile(Home "single.tab")
  }
  else {
    # fp = sys2var(Exe["timeout"] " 5m " Exe["mysql"] " --defaults-file=" shquote(G["my.cnf"]) " -h enwiki.analytics.db.svc.eqiad.wmflabs enwiki_p < " shquote(G["shadows.sql"]))   
    fp = sys2var(Exe["timeout"] " 30m " Exe["shadows.py"] )   
  }

  # print fp > "/data/project/botwikiawk/shadows/debug"

  if(!empty(fp)) {
    for(i = 1; i <= splitn(fp "\n", a, i, 1); i++) {
      if(debug && i == 5) 
          break
      SQL["File:" strip(a[i])]
      #if(a[i] ~ /[0-9]{1,}\tFile[:]/)             # 123456<tab>File:dig.jpg
      #  SQL[strip(splitx(a[i],"\t",2))] = 1       # SQL["File:dig.jpg"] = 1
    }
    if(length(SQL) > 0) {
      for(k in SQL) {
        if(debug) print "  Processing2 " k >> LogError
        if(! check_discovered(k)) {
          if(entity_exists(G["apiURLenwiki"], k)) {
            if(entity_exists(G["apiURLcommons"], k)) 
              shadows(k)
            else
              print k " ---- " curtime() " ---- entity missing from commons" >> LogError
          }
          else
            print k " ---- " curtime() " ---- entity missing from enwiki" >> LogError
        }
        else {
          if(debug)
            print k " ---- skipping due to existence in discovered" >> LogError
        }
      }
    }
    else
      print " ---- " curtime() " ---- No records in SQL table" >> LogError
  }
  else 
    print " ---- " curtime() " ---- No data returned by SQL query" >> LogError
}

#
# Add the template, handle preexisting templates
#
function shadows(entity,  re,re1,re2,fp,dest,reason) {

  # Skip troubled pages
  if(entity == "File:Information_icon.svg") {
    return 0
  }

  # retrieve wikisource

  fp = sys2var(Exe["wikiget"] " -w " shquote(entity))

  re["Space"] = "[\n\r\t]*[ ]*[\n\r\t]*[ ]*[\n\r\t]*"

  # -------------- Rules ---------------

  # Skip images containing these
  re["ShadowsCommons"] = "(shadows[ ]*commons)"
  re["Protection"] = "(PROTECTIONLEVEL[ ]*[:])"
  re["NowCommons"] = "(now[ ]*commons(this)?|commonsnow|db[-]?now[-]?commons|NCT?|uploaded to commons)"

  # Convert these to {{ShadowsCommons |keeplocal=yes}}
  re["KeepLocal"] = "(keep[ ]*local|no[ ]*commons)"

  # Add {{ShadowsCommons}} to images with these
  # re["DoNotMove"] = "(do not (move|copy) to (wikimedia[ ])?commons|dnmtc|never copy to wikimedia commons|no commons|notforcommons|pd[-]us but not country of origin)"
  # Templates with {{Do not move to Commons}} embedded:
  #  PD-USonly
  #  PD-ineligible-USonly
  #  PD-HHOFFMANN
  #  PD-US-expired-abroad
  #  Possibly non-free in US 
  #  FoP-USonly 
  #  Photo of art 
  #  FoP-unknown

  # -------------------------------------

  # If preexisting ShadowsCommons or PROTECTIONLEVEL or NowCommons then skip and log
  # These (except PROTECTIONLEVEL) are already filtered out in shadows.sql .. but to be safe..
  re1 = "[{]" reSpace "[{]" reSpace re["ShadowsCommons"] "|" re["Protection"] "|" re["NowCommons"] reSpace "[}]" reSpace "[}]"
  re2 = "[{]" reSpace "[{]" reSpace re["ShadowsCommons"] "|" re["Protection"] "|" re["NowCommons"] reSpace "[|][^}]*[}]" reSpace "[}]"
  if(match(fp, re1 "|" re2, dest)) {
    print entity " ---- " curtime() " ---- skip adding, it contains " dest[0] >> LogError
    return 0
  }

  # If a preexisting KeepLocal, replace with ShadowsCommons including the |reason 
  re1 = "[{]" reSpace "[{]" reSpace re["KeepLocal"] reSpace "[}]" reSpace "[}]"
  re2 = "[{]" reSpace "[{]" reSpace re["KeepLocal"] reSpace "[|][^}]*[}]" reSpace "[}]"
  if(match(fp, re1 "|" re2, dest)) {
    print entity " ---- " curtime() " ---- image contains " dest[0] >> LogError
    if(match(dest[0], /[|][ ]*reason[ ]*[=][^}\|]*[^}\|]/, dest2)) 
      reason = " |reason=" gsubi("^[|][ ]*reason[ ]*[=][ ]*", "", dest2[0])
    else
      reason = ""
    fp = gsubs(dest[0], "{{ShadowsCommons |keeplocal=yes" reason BotMsg "}}", fp)
    print entity " ---- " curtime() " ---- Added template with keeplocal" >> LogError
    return upload(fp, entity, Sum, G["log"], BotName, "en")
  }

  # Otherwise, add the template
  else {
    fp = "{{ShadowsCommons" BotMsg "}}\n" fp
    print entity " ---- " curtime() " ---- Added template" >> LogError
    return upload(fp, entity, Sum, G["log"], BotName, "en")
  }
}

#
# entity_exists - see if a page exists
#
function entity_exists(urlhead, entity   ,url,jsonin) {   
        url = urlhead "action=query&titles=" urlencodeawk(entity) "&format=json"
        jsonin = http2var(url)
        if (jsonin ~ "\"missing\"")  # sigh
            return 0
        return 1
}    

#
# Check if entity exists in DISC[]
#
function check_discovered(entity,  k) {
  for(k in DISC) 
    if(k == entity)
      return 1
  return 0
}
#
# Load DISC[] with contents of Log "discovered"
#
function load_discovered() {
  if(checkexists(Log "discovered")) 
    splitn(Log "discovered", DISC)
}

function curtime() {
  return sys2var(Exe["date"] " +\"%Y%m%d-%H:%M:%S\"")
}

