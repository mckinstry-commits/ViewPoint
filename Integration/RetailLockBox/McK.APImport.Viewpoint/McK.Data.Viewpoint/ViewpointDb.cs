using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using McK.APImport.Common;

namespace McK.Data.Viewpoint
{
    public class ViewpointDb
    {
        public ViewpointDb()
        {
            connectionString = CommonSettings.ViewpointConnectionString;
        }

        private static string connectionString;
        private static string ConnectionString
        {
            get
            {
                if (string.IsNullOrEmpty(connectionString))
                {
                    connectionString = CommonSettings.ViewpointConnectionString;
                }
                return connectionString;
            }
        }

        public static List<mvwAPAllInvoice> GetAllAPInvoices()
        {
            string sql = @"SELECT * FROM mvwAPAllInvoices";
            List<mvwAPAllInvoice> list;
            mvwAPAllInvoice record = default(mvwAPAllInvoice);

            try
            {
                using (var _conn = new SqlConnection(connectionString))
                {
                    _conn.Open();

                    using (var _cmd = new SqlCommand(sql, _conn))
                    {
                        _cmd.CommandTimeout = 600;

                        list = new List<mvwAPAllInvoice>();

                        using (var reader = _cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                record = new mvwAPAllInvoice();

                                // populate 'record' from reader
                                DataHelper.ReaderToModel(reader, record);

                                list.Add(record);
                            }
                        }
                    }
                }
            }
            catch (Exception e) { throw new Exception("ViewpointDb.GetAllAPInvoices: \n" + e.Message); }

            return list;
        }

        public static HQAT GetAttachmentRecord(int? attachmentID)
        {
            HQAT record = new HQAT();

            if (attachmentID.HasValue)
            {
                string sql = @"SELECT * FROM dbo.HQAT WHERE AttachmentID = " + attachmentID.Value;

                try
                {
                    using (var _conn = new SqlConnection(connectionString))
                    {
                        _conn.Open();

                        using (var _cmd = new SqlCommand(sql, _conn))
                        {
                            _cmd.CommandTimeout = 600;

                            using (var reader = _cmd.ExecuteReader())
                            {
                                while (reader.Read())
                                {
                                    record = new HQAT();

                                    // populate 'record' from reader
                                    DataHelper.ReaderToModel(reader, record);
                                }
                            }
                        }
                    }
                }
                catch (Exception e) { throw new Exception("ViewpointDb.GetAttachmentRecord: \n" + e.Message); }
            }
            return record;
        }

        public static APUI GetAPUIRecord(long? keyID)
        {
            APUI record = new APUI();

            if (keyID.HasValue)
            {
                string sql = @"SELECT * FROM dbo.APUI WHERE KeyID = " + keyID.Value;

                try
                {
                    using (var _conn = new SqlConnection(connectionString))
                    {
                        _conn.Open();

                        using (var _cmd = new SqlCommand(sql, _conn))
                        {
                            _cmd.CommandTimeout = 600;

                            using (var reader = _cmd.ExecuteReader())
                            {
                                while (reader.Read())
                                {
                                    record = new APUI();

                                    // populate 'record' from reader
                                    DataHelper.ReaderToModel(reader, record);
                                }
                            }
                        }
                    }
                }
                catch (Exception e) { throw new Exception("ViewpointDb.GetAPUIRecord: \n" + e.Message); }
            }
            return record;
        }

        public static bool APRecordExitsInViewpoint(RLBAPImportDetail record, List<mvwAPAllInvoice> allInvoices)
        {
            bool exists = false;
            if (!string.IsNullOrEmpty(record.CollectedInvoiceNumber))
            {
                exists = allInvoices.Any(h => (h.APRef == record.CollectedInvoiceNumber)
                    && ((h.InvTotal - record.CollectedInvoiceAmount) == 0));
            }
            return exists;
        }
    }
}
