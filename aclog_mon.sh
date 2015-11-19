#!/bin/sh

serverIp='10.1.0.1'
basePath='/data1/logs/'
# 日志文件名前缀
logFileSet=(
	'sample.com-access_'
)
# project paths (the number 0 is the index of the logFileSet)
# 子项目自定路径（数字0为日志文件名集logFileSet对应下标
project_0='/ /path/'

# average request_time projectId
# 平均响应时间项目id集
timeId_0='38 39'
# average request_time early warning value
# 平均响应时间预警值集
timeEarlyWarning_0='1 1'
# average request_time warning value
# 平均响应时间报警值集
timeWarning_0='2 2'
# average request_time early warning message
# 平均响应时间预警提示文案集
timeEarlyWarningMsg_0='www平均用时预警 分享平均用时预警'
# average request_time warning message
# 平均响应时间报警提示文案集
timeWarningMsg_0='www平均用时报警 分享平均用时报警'

# status projectId
# 50x响应状态项目id集
statusErrorId_0='35 36'
# status early warning value
# 50x响应状态预警值集
statusErrorEarlyWarning_0='50 50'
# status warning value
# 50x响应状态报警值集
statusErrorWarning_0='100 70'
# status early warning message
# 50x响应状态预警值提示文案集
statusErrorEarlyWarningMsg_0='www50x响应预警 分享50x响应预警'
# status warning message
# 50x响应状态报警值提示文案集
statusErrorWarningMsg_0='www50x响应报警 分享50x响应状态报警'

# status projectId
# 404响应状态项目id集
statusNotFoundId_0='35 36'
# status early warning value
# 404响应状态预警值集
statusNotFoundEarlyWarning_0='50 50'
# status warning value
# 404响应状态报警值集
statusNotFoundWarning_0='100 70'
# status early warning message
# 404响应状态预警值提示文案集
statusNotFoundEarlyWarningMsg_0='www404响应预警 分享404响应预警'
# status warning message
# 404响应状态报警值提示文案集
statusNotFoundWarningMsg_0='www404响应报警 分享404响应状态报警'

# fields position
# 数据列位置(useragent等字段有不定数量的空格，需要规避)
# NF: the last field
requestTimePos='NF'
# if read $request_time_msec, set requestTimeMultiple=1000
# 如果使用$request_time_msec字段，将requestTimeMultiple设为1000 （建议使用$upstream_response_time）
requestTimeMultiple=1
# if $time_local is placed before $request, manually add 1 to requestPos according to log_format in nginx.conf 
# 如果$time_local字段位于$request之前，根据log_format字段列的位置，手动加1，赋值到requestPos
requestPos=5
timelocalPos=3
# if $time_local is placed before $status, manually add 1 to statusPos according to log_format in nginx.conf 
# 如果$time_local字段位于$status之前，根据log_format字段列的位置，手动加1，赋值到statusPos
statusPos=6
# nginx处理时间，用于筛选499请求（$request_time_msec或$request_time）
nginxProcessTimePos="null"
# 如果使用$request_time字段，将nginxProcessTimeMultiple设为1000
nginxProcessTimeMultiple=1



# time range(seconds) for log scan
# 监控时长（单位为秒，一般为60秒）
timeRange=60

# ================== 自定义结束 ==================

endTimestamp=`date +%s`
startTimestamp=`expr $endTimestamp - $timeRange`
interfaceUrl='http://10.1.0.2/index.php?r=logsentinel/setdata'
interfaceHost='monitor.com'

#analyse access_log
for i in ${!logFileSet[*]}
do
eval project="\$project_""$i"
eval timeId="\$timeId_""$i"
eval timeEarlyWarning="\$timeEarlyWarning_""$i"
eval timeEarlyWarningMsg="\$timeEarlyWarningMsg_""$i"
eval timeWarning="\$timeWarning_""$i"
eval timeWarningMsg="\$timeWarningMsg_""$i"
eval statusErrorId="\$statusErrorId_""$i"
eval statusErrorEarlyWarning="\$statusErrorEarlyWarning_""$i"
eval statusErrorEarlyWarningMsg="\$statusErrorEarlyWarningMsg_""$i"
eval statusErrorWarning="\$statusErrorWarning_""$i"
eval statusErrorWarningMsg="\$statusErrorWarningMsg_""$i"
eval statusNotFoundId="\$statusNotFoundId_""$i"
eval statusNotFoundEarlyWarning="\$statusNotFoundEarlyWarning_""$i"
eval statusNotFoundEarlyWarningMsg="\$statusNotFoundEarlyWarningMsg_""$i"
eval statusNotFoundWarning="\$statusNotFoundWarning_""$i"
eval statusNotFoundWarningMsg="\$statusNotFoundWarningMsg_""$i"

# fetch file list
startFileTime=`date -d "1970-01-01 UTC ${startTimestamp} seconds" '+%Y%m%d%H%M'`
startFileTimeInterval=60;
# check log type
if [ ! -f "${basePath}${logFileSet[$i]}${startFileTime}.log" ]; then
    tmpStartTimestamp=`expr $endTimestamp - $timeRange - 60`
    tmpStartFileTimeMinute=`date -d "1970-01-01 UTC ${tmpStartTimestamp} seconds" '+%Y%m%d%H%M'`
    if [ ! -f "${basePath}${logFileSet[$i]}${tmpStartFileTimeMinute}.log" ]; then
        startFileTime=`date -d "1970-01-01 UTC ${startTimestamp} seconds" '+%Y%m%d%H'`
        startFileTimeInterval=3600;
    fi
fi

fileSuffix='log'
logFileNames=''
startFileTimestamp=`expr ${endTimestamp} + ${startFileTimeInterval}`
while (true)
do
    tmpFileName=${basePath}${logFileSet[$i]}${fileSuffix}
    logFileNames=${tmpFileName}' '${logFileNames}

    # check the current log
    checkResult=`head -n 1 ${tmpFileName} | awk "
    {
        # analyse valid request only
        # format datetime to transform it into timestamp
        split(\\$(${timelocalPos}), timeArr, \":\");
        split(timeArr[1], dateArr, \"/\");
        if(index(dateArr[1], \"[\") > 0){
            dateArr[1]=substr(dateArr[1], 2);
        }
        monthTrans[\"Jan\"]=1;
        monthTrans[\"Feb\"]=2;
        monthTrans[\"Mar\"]=3;
        monthTrans[\"Apr\"]=4;
        monthTrans[\"May\"]=5;
        monthTrans[\"Jun\"]=6;
        monthTrans[\"Jul\"]=7;
        monthTrans[\"Aug\"]=8;
        monthTrans[\"Sep\"]=9;
        monthTrans[\"Oct\"]=10;
        monthTrans[\"Nov\"]=11;
        monthTrans[\"Dec\"]=12;
        targetTimestamp=mktime(dateArr[3]\" \"monthTrans[dateArr[2]]\" \"dateArr[1]\" \"timeArr[2]\" \"timeArr[3]\" \"timeArr[4]);
        if(targetTimestamp > ${startTimestamp}){
            print 0;
        } else {
            print 1;
        }
    }"`
    # check if hit the target
    if [ ${checkResult} = 1 ]; then
        break
    else
        startFileTimestamp=`expr ${startFileTimestamp} - ${startFileTimeInterval}`
        if [ ${startFileTimeInterval} = 60 ]; then
            fileSuffix=`date -d "1970-01-01 UTC ${startFileTimestamp} seconds" '+%Y%m%d%H%M'`'.log'
        else
            fileSuffix=`date -d "1970-01-01 UTC ${startFileTimestamp} seconds" '+%Y%m%d%H'`'.log'
        fi
        # first check
        if [ ! -f "${basePath}${logFileSet[$i]}${fileSuffix}" ]; then
            sleep 5
            # second check
            if [ ! -f "${basePath}${logFileSet[$i]}${fileSuffix}" ]; then
                # check next log file
                startFileTimestamp=`expr ${startFileTimestamp} - ${startFileTimeInterval}`
                if [ ${startFileTimeInterval} = 60 ]; then
                    fileSuffix=`date -d "1970-01-01 UTC ${startFileTimestamp} seconds" '+%Y%m%d%H%M'`'.log'
                else
                    fileSuffix=`date -d "1970-01-01 UTC ${startFileTimestamp} seconds" '+%Y%m%d%H'`'.log'
                fi
                # if not exists, exit the loop
                if [ ! -f "${basePath}${logFileSet[$i]}${fileSuffix}" ]; then
                    break
                fi
            fi
        fi
    fi
done
echo $logFileNames

awk "
function escape(str) {
    shellCommand=\"echo -n '\"str\"'|od -An -tx1|tr ' ' %|tr -d '\n'\";
    shellCommand | getline res;
    close(shellCommand);
    return res
}
function valueCheck(result, projectIdStr, earlyWarningStr, warningStr, earlyWarningMsgStr, warningMsgStr){
    split(projectIdStr, projectId, \" \");
    split(earlyWarningStr, earlyWarning, \" \");
    split(warningStr, warning, \" \");
    split(earlyWarningMsgStr, earlyWarningMsg, \" \");
    split(warningMsgStr, warningMsg, \" \");
    for(i in result){
        state=1;
        earlyWarningInfo=\"\";
        warningInfo=\"\";
        if(result[i] >= earlyWarning[i]){
            state=2;
            earlyWarningInfo=escape(earlyWarningMsg[i] \",当前值\" result[i] \",预警值\" earlyWarning[i] \" ${serverIp} \" strftime(\"%Y-%m-%d %H:%M:%S\"));
        }
        if(result[i] >= warning[i]){
            state=3;
            warningInfo=escape(warningMsg[i] \",当前值\" result[i] \",报警值\" warning[i] \" ${serverIp} \" strftime(\"%Y-%m-%d %H:%M:%S\"));
        }
        curlCommand=\"curl -H 'Host: ${interfaceHost}' '${interfaceUrl}&projectId=\" projectId[i] \"&val=\" result[i] \"&state=\" state \"&advanceThresholdValue=\" earlyWarning[i] \"&reportThresholdValue=\" warning[i] \"&advanceThresholdStateInfo=\" earlyWarningInfo \"&reportThresholdStateInfo=\" warningInfo \"'\";
        print curlCommand;
        system(curlCommand);
    }
}


{
    # analyse valid request only
    if(\$(${requestPos}) != \"-\"){
        # format datetime to transform it into timestamp
        split(\$(${timelocalPos}), timeArr, \":\");
        split(timeArr[1], dateArr, \"/\");
        if(index(dateArr[1], \"[\") > 0){
            dateArr[1]=substr(dateArr[1], 2);
        }
        monthTrans[\"Jan\"]=1;
        monthTrans[\"Feb\"]=2;
        monthTrans[\"Mar\"]=3;
        monthTrans[\"Apr\"]=4;
        monthTrans[\"May\"]=5;
        monthTrans[\"Jun\"]=6;
        monthTrans[\"Jul\"]=7;
        monthTrans[\"Aug\"]=8;
        monthTrans[\"Sep\"]=9;
        monthTrans[\"Oct\"]=10;
        monthTrans[\"Nov\"]=11;
        monthTrans[\"Dec\"]=12;
        targetTimestamp=mktime(dateArr[3]\" \"monthTrans[dateArr[2]]\" \"dateArr[1]\" \"timeArr[2]\" \"timeArr[3]\" \"timeArr[4]);

        # use request timestamp to tell whether it needs to be analysed
        if(${endTimestamp}+0 >= targetTimestamp+0 && ${startTimestamp}+0 <= targetTimestamp+0){
            # add up request_time
            if(\$(${requestTimePos})+0 > 0){
                responseTimeData[\$((${requestPos})+1)]+=(\$(${requestTimePos}) / ${requestTimeMultiple});
            }

            if(\"${nginxProcessTimePos}\" == \"null\"){
                nginxProcessTime = 101;
            } else {
                nginxProcessTime = (\$(${nginxProcessTimePos}) * ${nginxProcessTimeMultiple});
            }

            # add up status
            tmpStatus=0;
            if(${statusPos} > ${requestPos}){
                tmpStatus=\$((${statusPos})+2)+0;
            } else {
                tmpStatus=\$(${statusPos})+0;
            }
            if(tmpStatus == 404){
                statusNotFoundData[\$((${requestPos})+1)]++;
            }
            if(tmpStatus >= 499){
                if(tmpStatus == 499){
                    if(nginxProcessTime > 50){
                        statusErrorData[\$((${requestPos})+1)]++;
                    }
                } else {
                    statusErrorData[\$((${requestPos})+1)]++;
                }
            }
        }
    }
}END{
    # selected projects filter
    split(\"${project}\", projects, \" \")

    # calculate request_time data
    # initial request_time result array
    for(i in projects){
        resultTime[i] = 0;
    }
    # calculate it!
    for(j in responseTimeData){
        for(k in projects){
            # dynamic file
            if(index(j, projects[k]) == 1){
                resultTimeSum[k]+=responseTimeData[j];
                resultTimeCount[k]++;
            }
            # static file
            if(match(j, \"^https?://.+?(com|net)\" projects[k]) > 0){
                resultTimeSum[k]+=responseTimeData[j];
                resultTimeCount[k]++;
            }
        }
    }
    for(i in resultTimeSum){
        resultTime[i] = (resultTimeSum[i] / resultTimeCount[i]);
    }
    valueCheck(resultTime, \"${timeId}\", \"${timeEarlyWarning}\", \"${timeWarning}\", \"${timeEarlyWarningMsg}\", \"${timeWarningMsg}\");

    # calculate status data
    # initial status result array
    for(i in projects){
        # status 50x result
        resultError[i] = 0;

        # status 404 result
        resultNotFound[i] = 0;
    }
    # calculate it!
    # status 50x
    for(j in statusErrorData){
        for(k in projects){
            # dynamic file
            if(index(j, projects[k]) == 1){
                resultError[k] += statusErrorData[j];
            }
            # static file
            if(match(j, \"^https?://.+?(com|net)\" projects[k]) > 0){
                resultError[k] += statusErrorData[j];
            }
        }
    }
    valueCheck(resultError, \"${statusErrorId}\", \"${statusErrorEarlyWarning}\", \"${statusErrorWarning}\", \"${statusErrorEarlyWarningMsg}\", \"${statusErrorWarningMsg}\");
    # status 404
    for(j in statusNotFoundData){
        for(k in projects){
            # dynamic file
            if(index(j, projects[k]) == 1){
                resultNotFound[k] += statusNotFoundData[j];
            }
            # static file
            if(match(j, \"^https?://.+?(com|net)\" projects[k]) > 0){
                resultNotFound[k] += statusNotFoundData[j];
            }
        }
    }
    valueCheck(resultNotFound, \"${statusNotFoundId}\", \"${statusNotFoundEarlyWarning}\", \"${statusNotFoundWarning}\", \"${statusNotFoundEarlyWarningMsg}\", \"${statusNotFoundWarningMsg}\");
}" ${logFileNames}
done

