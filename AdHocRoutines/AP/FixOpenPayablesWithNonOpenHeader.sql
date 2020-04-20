USE Viewpoint
go

--Queries to find target AP transaction records
--SELECT * FROM APTH WHERE Vendor=54099 AND APRef='8431' AND APCo<100
--SELECT * FROM APTL WHERE Mth='8/1/2014' AND APTrans=3326 AND APCo=20
--SELECT * FROM APTD WHERE Mth='8/1/2014' AND APTrans=3326 AND APCo=20

--Query to Update AP Transaction Header to be in an Open status instead of the original Closed status
--UPDATE APTH SET OpenYN='Y' WHERE Vendor=54099 AND APRef='8431' AND APCo<100


--Query to find AP transactins that are not Open but have detail records that are not paid.

SELECT
	apth.APCo
,	apth.Mth
,	apth.APTrans
,	apth.OpenYN
,	COALESCE(apth.InvTotal,0) AS HeaderTotal
,	COALESCE(SUM(aptd_paid.Amount),0) AS UnpaidTotal
FROM
		APTH apth
JOIN	APTD aptd_paid ON 
			apth.APCo < 100
		AND	apth.APCo=aptd_paid.APCo
		AND apth.Mth=aptd_paid.Mth
		AND apth.APTrans=aptd_paid.APTrans
		AND apth.OpenYN='N'
		AND aptd_paid.PaidDate IS NULL
GROUP BY
	apth.APCo
,	apth.Mth
,	apth.APTrans
,	apth.OpenYN
,	COALESCE(apth.InvTotal,0)
HAVING
	COALESCE(SUM(aptd_paid.Amount),0) <> 0
ORDER BY 1,2,3

