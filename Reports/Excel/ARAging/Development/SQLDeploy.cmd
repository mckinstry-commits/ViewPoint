sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\1_budARAgingHistory.sql -o 1_budARAgingHistory.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\2_mfnGetARCollectionNotes.sql -o 2_mfnGetARCollectionNotes.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\3_mfnGetARRelatedProjMgrs.sql -o 3_mfnGetARRelatedProjMgrs.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\4_mfnGetARTranHistory.sql -o 4_mfnGetARTranHistory.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\5_mfnARAgingDetail.sql -o 5_mfnARAgingDetail.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\6_mfnARAgingSummary.sql -o 6_mfnARAgingSummary.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\7_mspARAgeCustCont.sql -o 7_mspARAgeCustCont.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d Viewpoint -E -i ..\SQL\8_mspRefreshARAging.sql -o 8_mspRefreshARAging.txt
sqlcmd -S MCKTESTSQL04\VIEWPOINT -d msdb -E -i ..\SQL\9_SQLAgent_Job_AR_Aging_Refresh.sql -o 9_SQLAgent_Job_AR_Aging_Refresh.txt

