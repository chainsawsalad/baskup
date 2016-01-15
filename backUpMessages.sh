#!/bin/sh

#  backUpMessages.sh
#
#
#  Created by Peter Kaminski on 7/17/15.
# Main code can be found at https://github.com/kyro38/MiscStuff/blob/master/OSXStuff/.bashrc
# However I have tweaked it a bit to optimize the result

cwd=`pwd`

#Read all information that our python script dug up
while IFS='' read -r line || [[ -n $line ]]; do

contact=$line
arrIN=(${contact//;/ })
contactNumber=${arrIN[2]}
#Get to the working directory directory
cd $cwd
#Make a directory specifically for this folder
mkdir -p $contactNumber
#Now get into the directory
cd $contactNumber
#Perform SQL operations
sqlite3 ~/Library/Messages/chat.db "
select message.is_from_me,
    handle.id as handle_name,
    '(',
    datetime(message.date + strftime('%s', '2001-01-01 00:00:00'), 'unixepoch', 'localtime') as date,
    '): ',
    message.text
  from message
  join handle on handle.ROWID=message.handle_id
  where message.handle_id=(
    select chat_handle_join.handle_id from chat_handle_join where chat_handle_join.chat_id=(
      select chat.ROWID from chat where chat.guid='$line'
    )
  )" | sed 's/^1\|[^|]*\|/Me/;s/^0\|//;s/\|//g' > $line.txt

cd $cwd
cd $contactNumber
mkdir -p "Attachments"
cd "Attachments"
#Retrieve the attached stored in the local cache

sqlite3 ~/Library/Messages/chat.db "
select filename from attachment where rowid in (
select attachment_id from message_attachment_join where message_id in (
select rowid from message where cache_has_attachments=1 and handle_id=(
select handle_id from chat_handle_join where chat_id=(
select ROWID from chat where guid='$line')
)))" | cut -c 2- | awk -v home=$HOME '{print home $0}' | tr '\n' '\0' | xargs -0 -t -I fname cp fname .
$line
done < "$1"