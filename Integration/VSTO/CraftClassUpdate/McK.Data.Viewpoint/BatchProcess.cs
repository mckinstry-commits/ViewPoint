using System;
using System.Data;
using System.Data.SqlClient;

namespace McK.Data.Viewpoint
{
    public static partial class Batch
    {
        //public static IProgress<int> IProgress { get; set; }
        public static System.Threading.CancellationTokenSource CancelToken { get; set; }

        /// <summary>
        /// Process all records in batch
        /// </summary>
        /// <param name="batchId">Batch Id of current Craft Class Update</param>
        public static void Process(uint? batchId)
        {
            if (batchId == null) throw new Exception("Missing required Batch ID to process users");

            SqlParameter _batchId = new SqlParameter("@Rbatchid", SqlDbType.Int)
            {
                SqlValue = batchId
            };
            SqlCommand _cmd = null;

            //throw new Exception("Test");

            try
            {
                using (var _conn = new SqlConnection(HelperData._conn_string))
                {
                    _conn.Open();
                    //_conn.InfoMessage += new SqlInfoMessageEventHandler(ProgressStatus); //get updates from the database

                    using (_cmd = new SqlCommand("dbo.MCKspPRClassRateProcess", _conn))
                    {
                        CancelToken.Token.ThrowIfCancellationRequested();
                        CancelToken.Token.Register(() => _cmd?.Cancel());

                        _cmd.CommandType = CommandType.StoredProcedure;
                        _cmd.Parameters.Add(_batchId);
                        _cmd.CommandTimeout = 0;
                        _cmd.ExecuteScalar();
                    }
                } 
            }
            catch (Exception ex)
            {
                ex.Data.Add(0, "Batch.Process");
                throw ex;
            }
        }
        //private static void ProgressStatus(object sender, SqlInfoMessageEventArgs e) => IProgress.Report(e.Errors[0].State);// update progress bar on UI

        // time how long code takes to complete
        //public static double Time(Func<System.Threading.Tasks.Task> func, int iters = 10)
        //{
        //    var sw = System.Diagnostics.Stopwatch.StartNew();
        //    for (int i = 0; i < iters; i++) func().Wait();
        //    return sw.Elapsed.TotalSeconds / iters;
        //}

        //public static TimeSpan Time(Action action)
        //{
        //    var sw = System.Diagnostics.Stopwatch.StartNew();
        //    //for (int i = 0; i < iters; i++) action
        //    action();
        //    return sw.Elapsed;
        //}
    }
}

