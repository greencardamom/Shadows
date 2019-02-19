Shadows
===================
by User:GreenC (en.wikipedia.org)
Copyright 2019
MIT License

Info
========
Shadows is a Wikipedia bot to add {{Shadows Commons}} to File: pages 

See [WP:Bots/Requests for approval/GreenC bot 10](https://en.wikipedia.org/wiki/User:GreenC_bot/Job_10)

It connects to the SQL replicas thus can only be run on Toolforge.

Requirements
========
* GNU Awk 4.1+
* [BotWikiAwk](https://github.com/greencardamom/BotWikiAwk) (version Jan 2019 +)

Installation
========

1. Install BotWikiAwk and follow setup instructions. Add OAuth credentials to wikiget.

2. Clone Reftalk. For example:
	git clone https://github.com/greencardamom/Reftalk

3. Edit ~/BotWikiAwk/lib/botwiki.awk

	A. Set local URLs in section #1 and #2 

	B. Create a new 'case' entry in section #3, adjust the Home bot path created in step 3:

		case "shadows":                                             # Custom bot paths
			Home = "/data/project/projectname/Shadows/"         # path ends in "/"
			Agent = UserPage " (ask me about " BotName ")"
			break

	C. Add a new entry in section #10 (inside the statement if(BotName != "makebot") {} )

		if(BotName !~ /shadows/) {
			delete Config
			readprojectcfg()
		}

4. Set ~/Shadows/shadows.awk to mode 750, set the first shebang line to location of awk

Running
========

3. Run reftalk

     On Toolforge from the command-line:

       /usr/bin/jsub -once -quiet -N shadows.awk -l mem_free=50M,h_vmem=100M -e /data/project/botwikiawk/Shadows/shadows.stderr -o /data/project/botwikiawk/Shadows/shadows.stdout -v "AWKPATH=.:/data/project/botwikiawk/BotWikiAwk/lib" -v "PATH=/sbin:/bin:/usr/sbin:/usr/local/bin:/usr/bin:/data/project/botwikiawk/BotWikiAwk/bin" -wd /data/project/botwikiawk/Shadows /data/project/botwikiawk/Shadows/shadows.awk

     On Toolforge from cron, the crontab would contain:

       SHELL=/bin/bash
       PATH=/sbin:/bin:/usr/sbin:/usr/local/bin:/usr/bin:/data/project/botwikiawk/BotWikiAwk/bin
       AWKPATH=.:/data/project/botwikiawk/BotWikiAwk/lib
       MAILTO= an email address for reporting when cron runs (this is disabled with -quiet)
       HOME=/data/project/botwikiawk
       LANG=en_US.UTF-8
       LC_COLLATE=en_US.UTF-8
       37 4 * * * /usr/bin/jsub -once -quiet -N shadows.awk -l mem_free=50M,h_vmem=100M -e /data/project/botwikiawk/Shadows/shadows.stderr -o /data/project/botwikiawk/Shadows/shadows.stdout -v "AWKPATH=.:/data/project/botwikiawk/BotWikiAwk/lib" -v "PATH=/sbin:/bin:/usr/sbin:/usr/local/bin:/usr/bin:/data/project/botwikiawk/BotWikiAwk/bin" -wd /data/project/botwikiawk/Shadows /data/project/botwikiawk/Shadows/shadows.awk

     ie. check at 4:37am (GMT) once a day

4. Monitor ~/Shadows/log files discovered, error and syslog

5. To stop and restart

     To stop on Toolforge

       qstat  (display the job number)
       qdel <job #>

     To restart, see step #3. 
