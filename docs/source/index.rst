================
UNOMENA make-env
================

********
Synopsis
********

At UNOMENA, we have multiple environments: DEV, QA, MOCK, STAGE & PROD. We try to keep all of these fairly similar, or as close possible at all times. This simplifies and eases the process to move form one to the other.

DEV, QA & MOCK are non-production environments, while STAGE & PROD are considered live at all times. DEV is only accessible to internal UNOMENA staff, but clients may and are encouraged to view all the others.

We build things locally in feature branches and merge them to develop, to test them on DEV. Once a developer is happy with what they see, the feature branch can be merged to QA. DO NOT MERGE develop OR qa INTO ANY BRANCH. DO NOT BRANCH OFF ANY OF THOSE EITHER. develop is deployed on DEV and qa on QA. We bounce the concept code off the client and have our QA team test it. When the ticket / feature is ready to be deployed to PROD, we prepare a release branch, based off master, and deploy that to MOCK. It eventually progresses to STAGE and finally to PROD.

The ideal is to have an automated, repeatable and predictable process, which is similar in use, yet specific to each environment. On each of these platforms code gets deployed to, there is a Makefile in the /home/ubuntu folder. This document describes the use of that Makefile. Good luck, it's not so difficult.  ;)

*******************
What is a Makefile?
*******************

A makefile is a special file, containing shell commands, that you create and name Makefile. While in the directory containing this Makefile, you will type make and the commands in the Makefile will be executed.

*****************************************
What's in UNOMENA's environment Makefile?
*****************************************

There are command to easily do often-run commands. Here is the full list:

- help: Displays a brief help guide about the Makefile
- replace-db: Dumps the database and backs it up on S3; downloads the latest copy of the PROD database and installs it in place. (Not available on STAGE or PROD)
- deploy-code: Checks out the latest version of code and runs the relevant build file.
- replace-media: Drops the existing media & gets the latest copy from STAGE. (Not available on STAGE or PROD)
- update: All for the above (Except help) (Not available on STAGE or PROD)

