using System;
using System.Collections.Generic;
using System.Windows.Forms;
//using Office = Microsoft.Office.Core;
using Excel = Microsoft.Office.Interop.Excel;
using Office = Microsoft.Office.Tools;
using McK.Data.Viewpoint;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using McK.ExtensionMethods;
//using McK.ExtensionMethods;

//using System.Diagnostics;

/// <summary>
///  ********  THIS VSTO CANNOT RUN SIDE-BY-SIDE; NEED TO UNINSTALL AND RESINTALL TO RUN ON DIFFERENT ENVIRONMENTS ********
///  **IMPORTANT!** PRODUCT Name determines environment SQL connection
/// </summary>
namespace MCK.CraftClass.Viewpoint
{
    /*******************************************************************************************************************************************************;
                                                                                                                   
                                           McKinstry Craft Class Update                                           
                                                                                                                    
                                            copyright McKinstry 2017                                               
                                                                                                                   
        This Microsoft Excel VSTO solution was developed by McKinstry in 2017 in order to faciliate updates to      
        rates for Craft Classes within Vista by Viewpoint.  This software is the property of McKinstry and         
        requires express written permission to be used by any Non-McKinstry employee or entity.                    
                                                                                                                    
        Release                    Pub Date             Details                                               
        -------                    --------             ------------------                                               
        1.0.0.0 Initial Release    4/28/2017            Excel VSTO/SQL Dev:  Leo Gurdian                     
                                                              Viewpoint/SQL  Dev:  Arun Thomas                      
                                                              Project Manager:     Theresa Parker                  
                                       
        1.0.0.1 major       5/10/2017          - Change architecture from Document-level to Application Add-In to avoid copy-paste to tamplate                                                        
                                                            - SQL validation to exclude partial updates, only full updates allowed
                                                            - if no changes, no updates are made
        1.0.0.2 minor       5/26/2017              - removed JCCo that was limiting only 1 company update per batch
                                                              as opposed to having a batch that can update multiple companies
        1.0.0.3 minor       5/26/2017              - Changed JCCo from TinyInt to Int to accomodate for triple digits
                                                              On no updates due to no changes, display message
        1.0.0.4 minor       5/30/2017              - highlight missing rate for dedns liabs and addon earnings
                                                            - removed self-destruction of msg when no updates
        1.0.0.5 minor       5/31/2017              - bug fix "object reference not set to an instance of an object" in 3-pair extraction algorithm       
        1.0.0.6 minor       8/2/2017               - faster display errors
                                                            - Variance reports: write arrays to sheet vs cell-by-cell
                                                            - All queries use faster List<T> vs bulky DataTables
                                                            - inserting rows above header won't break app and no error msgs
                                                            - Load Y/N drives updates. No messages unless errors or variances.
                                                            - Removed the Error tab each time the update is ran to get rid of errors that may have been fixed
                                                            - Error message for missing rates/amounts/fields changed to:
                                                                    -> “Missing rate. See highlighted cell.” (pay rates)
                                                                    -> “Missing amount. See highlighted cell.” (3-pairs dedns liabs and add-on earnings)
                                                                    -> "Missing required field. See highlighted cell." (craft class)
                                                            - 3 buttons added: 'Crafts to be Updated', 'Check Variances' and 'Show/Hide Pane'
        1.0.0.7 minor       8/17/2017               - Variance reports now show 'Craft Classes in Viewpoint, not in Excel'
                                                                    -> Only variances show with the exception of Craft Classes in Viewpoint w/ no data; 
                                                                       those show as zero, Excel show as zero so there’s  ‘no variance’ but they will still be included in the report.
                                                            - Added "Are you sure you want to update rates" dialog prompt
                                                            - Updated the missing fields logic.  The ‘missing’ field is highlighted in the following cases:
                                                                a.	Shift is missing, not Amount 
                                                                b.	Amount  is missing, not Shift
                                                                c.	Amount  is missing, not Earn Code / Factor
                                                                d.	Earn Code is missing, not Factor / Amount 
                                                                e.	Earn Code / Amount  is missing, not Factor
                                                                f.	Factor is missing, not Earn Code / Amount 
                                                                g.	Amount  is missing, not DL Code / Factor
                                                                h.	DL Code is missing, not Factor / Amount 
                                                                i.	Dl Code / Amount is missing, not factor
                                                                j.	Factor is missing, not DL Code / Amount 
                                                                k.	If DL Code is NOT missing but Factor and Amount  for all 3 slots are missing, the row is skipped.
                                                                l.	If Earn Code is NOT missing but Factor and Amount  for all 3 slots are missing, the row is skipped.
                                                                m.	If DL Code, Factor and Amount  for all 3 slots are missing, the row is skipped.
                                                                n.	If Earn Code, Factor and Amount  for all 3 slots are missing, the row is skipped.
                           9/18/2017               - publish corrected file version .6 to .7 
       1.0.0.8             9/20/2017               - 'Show/Hide Pane' now shows ActionPane on current Active Window when multiple workbooks are open
                           10/04/2017              - piggy back update: added environment + version label to ribbon menu
       1.0.0.9             10/20/2017              - FIX: 'Object reference not set to an instance of an object" when Y/N empty     
       1.0.0.10            11/6/2017               - When 'no craft classes selected for loading" show user in place of unhelpful error
                                                            - FIX  'Object reference not set to an instance of an object' on empty structures
       1.0.1.0             3.15.2017           - Axosoft # 101648 
                                                - Variance reports
                                                    - Don't show zero deltas in Variance
                                                    - Add decimal place to Deltas
                                                - Flip all Load filter to 'N' correctly
                                                - Faster 'Craft to be Updated' and correctly show Co and Craft  
                                                - Fixed error: 'sticking' pane to active workbook: "Collection was modified; enumeration operation may not execute."
                                                - Protected view alert
                                                - Put reports in originating workbook not others opened
       1.0.1.1              3.29.18             - STAGING - SQL tuning
       1.0.1.2              4.09.18             - BUG FIX: "Cannot implicitly convert type 'string' to 'object[*,*]'" - GetClassColumn() now correctly handles single row
       1.0.1.3              5.31.18             - BUG FIX: FlipSuccessUpdatesToLoadFilterN failure; values are now set properly
                            6.14.18     PROD. RELEASE
                            6.18.19     STAGING: - environment label driven off db connection string rather than App Name
                                                 - sign certificate updated
       1.0.1.4  small       6.19.19     TFS 4747 - Can now add 3-pair DednsLiabs columns without incorrectly halting  with "Missing code"
       1.0.1.5  small       6.20.20     TFS 4747 - Fixed
     *********************************************************************************************************************************************************/
    public partial class TaskPaner : UserControl
    {
        internal static System.Configuration.AppSettingsReader _config => new System.Configuration.AppSettingsReader();

        internal Excel.Worksheet ws = null;
        private Excel.Range workingRange { get; set; }
        private uint? batchId;
        private int lastRow;

        // flaggin progress completion
        private bool success = false;
        private bool craftClassesInserted = false;
        private bool payratesInserted = false;
        private bool addonEarningsInserted = false;
        private bool dednsLaibsInserted = false;
        private bool batchProcessed = false;

        /// <summary>
        /// Header column ordinals used in the data layer to retrieve fields
        /// </summary>
        private dynamic headers; // System.Dynamic.ExpandoObject() as IDictionary<string, Object>; 
        private uint startRowData = 3;
        private int headerRow = 2;

        #region DATA STRUCTURES

        /// <summary>
        /// Rows to be loaded into staging tables
        /// </summary>
        private List<uint> loadRows;
        /// <summary>
        /// 2D user-input values 
        /// </summary>
        private object[,] craftClasses = null;

        /// <summary>
        /// Payrates: row, code and amount
        /// </summary>
        private Dictionary<uint, List<KeyValuePair<int, decimal>>> payrates;

        /// <summary>
        /// Addon-Earnings static (2 pair): code, amount
        /// </summary>
        private Dictionary<uint, List<KeyValuePair<int, decimal>>> addonEarnings_2pairs = null;
        /// <summary>
        /// Addon-Earnings variable (3-pairs): row | code, factor, amount
        /// </summary>
        private Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> addonEarnings_3pairs = null;

        /// <summary>
        /// Dedns-Liabs  static (2 pair):: code, amount
        /// </summary>
        private Dictionary<uint, List<KeyValuePair<int, decimal>>> dednsLiabs_2pairs = null;
        /// <summary>
        ///  Dedns-Liabs variable (3-pairs):: row | code, factor, amount
        /// </summary>
        private Dictionary<uint, List<KeyValuePair<int, KeyValuePair<decimal, decimal>>>> dednsLiabs_3pairs = null;

        private List<Dictionary<string, List<dynamic>>> varianceReports;
        #endregion

        private CancellationTokenSource cancelToken;

        // custom progress bar w/ percentage indicator
        //private MyProgressBar progBatchProcess;
 
        public TaskPaner()
        {
            InitializeComponent();
            try
            {
                #region custom progress bar
                // custom progress bar w/ percentage text drawing
                //progBatchProcess = new MyProgressBar()
                //{
                //    Name        = "progBatchProcess",
                //    Location    = new System.Drawing.Point(3, 339),
                //    Size        = new System.Drawing.Size(190, 22),
                //    Step        = 1,
                //    Visible     = true,
                //    Maximum     = 1,
                //    Minimum     = 0
                //};
                //this.Controls.Add(progBatchProcess);
                //progBatchProcess.Invalidate();
                #endregion

                HelperData._conn_string = (string)_config.GetValue("ViewpointConnection", typeof(string));


                #region ENVIRONMENTS label

                if (HelperData._conn_string.Contains("MCKTESTSQL05", StringComparison.OrdinalIgnoreCase))
                {
                    lblAppName.Text = "Dev";
                }
                else if (HelperData._conn_string.Contains("VPSTAGINGAG", StringComparison.OrdinalIgnoreCase))
                {
                    lblAppName.Text = "Stg";
                }
                else if (HelperData._conn_string.Contains("SEA-STGSQL01", StringComparison.OrdinalIgnoreCase))
                {
                    lblAppName.Text = "Proj";
                }
                else if (HelperData._conn_string.Contains("SEA-STGSQL02", StringComparison.OrdinalIgnoreCase))
                {
                    lblAppName.Text = "Upg";
                }
                else if (HelperData._conn_string.Contains("MCKTESTSQL01", StringComparison.OrdinalIgnoreCase))
                {
                    lblAppName.Text = "Trng";
                }
                else  if (HelperData._conn_string.Contains("VIEWPOINTAG"))
                {
                    lblAppName.Text = "Prod";
                }
                else
                {
                    lblAppName.Text = "Unspecified";
                }
                #endregion

                lblVersion.Text = "v" + this.ProductVersion;
                Globals.Ribbons.Ribbon1.grp.Label = Globals.Ribbons.Ribbon1.grp.Label + " (" + lblAppName.Text + " " + lblVersion.Text + ")";
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "TaskPane");
                ShowErr(ex);
            }
        }

        #region UPDATE CRAFT CLASSES

        public void UpdateCraftClasses()
        {
            Office.Ribbon.RibbonButton btn = Globals.Ribbons.Ribbon1.btnUpdate;

            if (btn.Label == "Update Rates")
            {
                try
                {
                    string msgCaption = "[Preparing Data]";
                    btn.Label = "Cancel";

                    lblProcessing.Text = msgCaption;
                    lblProcessing.Refresh();

                    if (!_1_CraftClassesExtract())
                    {
                        lblProcessing.Text = "[Status]";
                        btn.Label = "Update Rates";
                        return;
                    }

                    //ClearTextboxesProgressBars();
                    DeleteErrTab();
                    DeleteVarianceTabs();
                    varianceReports?.Clear();

                    // For Task.Run work properly around an MS BUG: http://stackoverflow.com/questions/32455111/hooked-events-outlook-vsto-continuing-job-on-main-thread
                    System.Threading.SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());

                    // gather all tasks that need to be run
                    List<Task> tasks = new List<Task>();
                    cancelToken = new CancellationTokenSource();


                    if (craftClasses != null && loadRows.Count > 0)
                    {
                        // create user batch
                        if (batchId == null) batchId = Batch.CreateBatch();
                        lblBatch.Text = batchId.ToString();
                        lblBatch.Refresh();

                        // Craft Classes
                        if (!craftClassesInserted)
                        {
                            tasks.Add(new Task(() =>
                            {
                                craftClassesInserted = Stage.CraftClasses(batchId, craftClasses, headers, loadRows, cancelToken) > 0;
                            }));
                        }

                        // Payrates
                        if (!payratesInserted)
                        {
                            if (Payrates_Extract()) tasks.Add(new Task(() =>
                            {
                                payratesInserted = Stage.Payrates(batchId, craftClasses, payrates, headers, cancelToken) > 0;
                            }));
                        }

                        // Addon Earnings
                        if (!addonEarningsInserted)
                        {
                            if (Addon_Earnings_Extract()) tasks.Add(new Task(() =>
                            {
                                addonEarningsInserted = Stage.AddonEarnings(batchId, craftClasses, addonEarnings_2pairs, addonEarnings_3pairs, headers, cancelToken) > 0;
                            }));
                        }

                        // Dedns & Liabs 
                        if (!dednsLaibsInserted)
                        {
                            if (Deductions_Liabilities_Extract()) tasks.Add(new Task(() =>
                            {
                                dednsLaibsInserted = Stage.DednsLiabs(batchId, craftClasses, dednsLiabs_2pairs, dednsLiabs_3pairs, headers, cancelToken) > 0;
                            }));
                        }

                        //IProgress<string> timer = new Progress<string>(elapsed => { MessageBox.Show(this, elapsed, lblProcessing.Text); });
                        //Stopwatch sw = Stopwatch.StartNew();

                        // spin ThreadPool only if needed
                        if (!craftClassesInserted || !payratesInserted || !addonEarningsInserted || !dednsLaibsInserted & !batchProcessed)
                        {
                            msgCaption = "[Preparing Data]";
                            // batch progress / status
                            IProgress<string> processingLbl = new Progress<string>(caption =>
                            {
                                lblProcessing.Text = msgCaption = caption;
                            });

                            IProgress<Dictionary<string, List<dynamic>>> _success = new Progress<Dictionary<string, List<dynamic>>>(failedValidationTables =>
                            {
                                ShowValidationErrReports(failedValidationTables);
                                lblProcessing.Text = "[Please Wait..]";
                                btn.Label = "Update Rates";

                                if (failedValidationTables.Any((table) => table.Value?.Count > 0))
                                {
                                    /* show correct user message for:
                                        1. success / no variances / errors 
                                        2. success / variances / errors
                                     see if there are succesfully updated classes not in the error report, if so, show "succesfully updated"
                                     get craft classes from error report */
                                    List<dynamic> badCraftClass = failedValidationTables.FirstOrDefault((t) => t.Key == "Craft Classes").Value;
                                    object[,] loadClasses = GetExcelUniqueCraftClasses();
                                    string msg = "";
                                    string caption = "";
                                    if (loadClasses.GetUpperBound(0) > badCraftClass.Count)
                                    {
                                        caption = "Some success";
                                        msg = "Some updates made but there were errors.\n\n";
                                    }
                                    else
                                    {
                                        caption = "Unsuccessful";
                                    }

                                    MessageBox.Show(null, msg + "Craft Classes with errors were not updated. See error report.", caption, MessageBoxButtons.OK, MessageBoxIcon.Error);
                                }
                                else
                                {

                                    int reportCnt = varianceReports.First().Count((table) => table.Value.Count > 0); // any variances ?
                                    
                                    MessageBox.Show(null, "Craft Classes successfully updated!\n\n"
                                                          + (reportCnt > 0 ? "Please review the Craft Class variance report" + (reportCnt > 1 ? "s!" : "") : "")
                                                            , "Success!", MessageBoxButtons.OK, MessageBoxIcon.Information);
                                }
                                FlipSuccessUpdatesToLoadFilterN(failedValidationTables);
                                lblProcessing.Text = "[Updates Completed]";
                                ResetFlags();
                                //progBatchProcess.Value = progBatchProcess.Maximum;
                                return;
                            });

                            IProgress<List<Dictionary<string, List<dynamic>>>> _diffs = new Progress<List<Dictionary<string, List<dynamic>>>>(tableDiffs =>
                            {
                                ShowVarianceReport(tableDiffs);
                                return;
                            });
                            IProgress<object[]> _failure = new Progress<object[]>(fail =>
                            {
                                Exception ex = null;
                                if (fail != null)
                                {
                                    ex = (Exception)fail[0];
                                    Dictionary<string, List<dynamic>> failedValidationTables = (Dictionary<string, List<dynamic>>)fail[1];
                                    ShowValidationErrReports(failedValidationTables);
                                }

                                MessageBoxIcon iconType = MessageBoxIcon.Exclamation;
                                string errmsg = null;
                                if (ex != null)
                                {
                                    lblProcessing.Text = "[Updates Completed]";
                                    lblProcessing.Refresh();
                                    msgCaption = "Success with post-completion error";
                                    errmsg = "Batch completed succesfully but..\n\n" + ex.Message;
                                    btn.Label = "Update Rates";
                                }
                                else
                                {
                                    if (!cancelToken.IsCancellationRequested)
                                    {
                                        msgCaption = msgCaption + " - " + ex.Data[0];
                                        lblProcessing.Text = "[Failed Updates]";
                                        lblProcessing.Refresh();
                                        iconType = MessageBoxIcon.Error;
                                        btn.Label = "Update Rates";
                                    }
                                    else
                                    {
                                        lblProcessing.Text = msgCaption = "[Updates Cancelled]";
                                        lblProcessing.Refresh();
                                    }

                                    if (ex != null)
                                    {// batch process sp (last task)
                                        errmsg = ex.Message.Contains("cancelled") ? "Operation Cancelled" : ex.Message;
                                        //errmsg = ex.Message.Contains("cancelled", StringComparison.OrdinalIgnoreCase) ? "Operation Cancelled" : ex.Message;
                                    }
                                    else
                                    {// 1 of the 4 staging tasks
                                        errmsg = "Operation Cancelled";
                                    }
                                    ResetFlags();
                                }
                                MessageBox.Show(this, errmsg, msgCaption, MessageBoxButtons.OK, iconType);
                                //timer.Report(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", sw.Elapsed.ToString()));
                                return;
                            });

                            Task.Run(() =>
                            {
                                //sw = Stopwatch.StartNew();
                                Parallel.ForEach(tasks, task => task.Start());
                                Task.WaitAll(tasks.ToArray());
                                //timer.Report(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", sw.Elapsed.ToString()));

                                if (cancelToken.Token.IsCancellationRequested)
                                {
                                    _failure.Report(null);
                                    return;
                                }

                                if (craftClassesInserted || payratesInserted || addonEarningsInserted || dednsLaibsInserted && !batchProcessed)
                                {
                                    processingLbl.Report("[Processing Updates]");
                                    Task.Run(() =>
                                    {
                                        Batch.CancelToken = cancelToken;
                                        try
                                        {
                                            //sw.Restart();
                                            //throw new Exception("Test");
                                            bool validated = Batch.Validate(batchId);
                                            ClassColumnValues = GetClassColumn(); // used by ExcludeLoadFilterN and FlipSuccessUpdatesLoadFilterToN (_success.Report)
                                            if (validated)
                                            {
                                                Batch.Process(batchId);
                                                batchProcessed = true;
                                                varianceReports = GetViewpointVariances();
                                                ExcludeLoadFilterN(varianceReports);
                                                _diffs.Report(varianceReports); // should be zero diffs if all updates went well
                                            }
                                            _success.Report(GetValidationErrsFromViewpoint());
                                        }
                                        catch (Exception ex)
                                        {
                                            processingLbl.Report("[Please wait...]");
                                            Dictionary<string, List<dynamic>> failedValidationTables = GetValidationErrsFromViewpoint();
                                            _failure.Report(new object[] { ex, failedValidationTables });
                                        }
                                    });
                                }
                                else
                                {
                                    _failure.Report(null); // no staged data
                                }
                            });
                        }
                    }
                    else
                    {
                        throw new Exception("No records selected for loading. Set the 'Load Y/N' filter.");
                    }
                }
                catch (Exception ex)
                {
                    HelperUI.RenderON();
                    if (ex.Data.Count == 0) ex.Data.Add(0, "UpdateCraftClasses");
                    btn.Label = "Update Rates";
                    ResetFlags();
                    ShowErr(ex);
                }
            }
            else if (btn.Label == "Cancel")
            {
                btn.Enabled = false;
                btn.Label = "Cancelling...";
                cancelToken.Cancel();
                btn.Enabled = true;
                btn.Label = "Update Rates";
                lblProcessing.Text = "[Cancelled Updates]";
            }
        }

        #endregion


        #region GENERATE LIST OF CRAFTS TO BE UPDATED REPORT

        public void CraftsToUpdateReport()
        {
            lblProcessing.Text = "[Reading Template..]";
            Office.Ribbon.RibbonButton btn = Globals.Ribbons.Ribbon1.btnCraftsToUpdate;
            Excel.ListObject xlTable = null;
            btn.Enabled = false;
            string craftsToBeUpdated = "Crafts to be Updated";

            try
            {

                if (!_1_CraftClassesExtract())
                {
                    lblProcessing.Text = "[Status]";
                    btn.Label = craftsToBeUpdated;
                    btn.Enabled = false;
                    return;
                }

                string sheetname = craftsToBeUpdated;
                ws = HelperUI.GetSheet(sheetname);

                if (ws != null)
                {
                    Globals.ThisAddIn.Application.DisplayAlerts = false;
                    ws.Delete();
                    Globals.ThisAddIn.Application.DisplayAlerts = true;
                }

                // Create new sheet
                ws = Globals.Ribbons.Ribbon1.MyActiveWorkbook.Sheets.Add(After: Globals.Ribbons.Ribbon1.MyActiveWorkbook.ActiveSheet);
                if (ws != null)
                {
                    HelperUI.RenderOFF();

                    ws.get_Range("A1").Formula = craftsToBeUpdated;
                    ws.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                    ws.get_Range("A1").Font.Bold = true;
                    ws.get_Range("A1").Font.Name = "Calibri";
                    ws.get_Range("A1").EntireRow.RowHeight = 45;
                    ws.get_Range("A1").HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                    ws.get_Range("A1").VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                    ws.get_Range("A1:C1").Merge();
                    ws.get_Range("A:C").EntireColumn.NumberFormat = "@";
                    ws.get_Range("A2").Formula = "Src";
                    ws.get_Range("B2").Formula = "Co";
                    ws.get_Range("C2").Formula = "Craft";
                    ws.Name = sheetname; // table.Key.Length > 31 ? table.Key.Substring(0, 31) : table.Key; // 31 = Excel's max tab name lenth
                    ws.Application.ActiveWindow.DisplayGridlines = false;

                    object[,] load = GetExcelUniqueCraftClasses(craftsOnly: true);

                    xlTable = HelperUI.FormatAsTable(ws.get_Range("A2:C" + (load.GetUpperBound(0) + 3)), "CraftsToBeUpdated", false, true);
                    xlTable.ShowTableStyleRowStripes = true;
                    xlTable.DataBodyRange.NumberFormat = "@";
                    xlTable.DataBodyRange.HorizontalAlignment = Excel.XlHAlign.xlHAlignCenter;
                    xlTable.ListColumns["Src"].DataBodyRange.EntireColumn.ColumnWidth = 10.57;
                    xlTable.ListColumns["Co"].DataBodyRange.EntireColumn.ColumnWidth = 4.57;
                    xlTable.ListColumns["Craft"].DataBodyRange.EntireColumn.ColumnWidth = 16.43;
                    xlTable.ListColumns["Src"].DataBodyRange.Formula = "Excel";
                    ws.get_Range(xlTable.ListColumns["Co"].DataBodyRange,
                                 xlTable.ListColumns["Craft"].DataBodyRange).set_Value(Excel.XlRangeValueDataType.xlRangeValueDefault, load);

                    //rng = this.ws.get_Range("B3:C" + lastRow);
                    //rng.AdvancedFilter(Excel.XlFilterAction.xlFilterCopy, CriteriaRange: Type.Missing, CopyToRange: rngDest, Unique: true); // but no Y/N load filter

                    //object cols = new object[] { 1, 2 };
                    //rng.RemoveDuplicates(cols, Excel.XlYesNoGuess.xlNo);
                    //rng.Copy(xlTable.DataBodyRange);
                    lblProcessing.Text = "[Done!]";
                }
            }
            catch (Exception ex)
            {
                lblProcessing.Text = "[Failure!]";
                errOut(ex, "Craft List Failure");
            }
            finally
            {
                if (xlTable != null) Marshal.ReleaseComObject(xlTable); xlTable = null; 
                if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                btn.Enabled = true;
                HelperUI.RenderON();
            }
        }

        internal void errOut(Exception ex, string title = "Oops") => MessageBox.Show(null, ex.Message, title, MessageBoxButtons.OK, MessageBoxIcon.Error);

        /// <summary>
        /// Collect unique Crafts per the Load Y/N filter (column A)
        /// </summary>
        /// <param name="craftsOnly"></param>
        /// <returns></returns>
        private object[,] GetExcelUniqueCraftClasses(bool craftsOnly = false)
        {
            int uniqueCraftCnt = 0;
            int colCnt = 3;
            object[,] load = new object[loadRows.Count, colCnt];
            bool exists = false;
            //int lastRow = uniqueCraftCnt;

            // loop rows to be loaded into staging tables
            for (int n = 0; n < loadRows.Count; n++)
            {
                var co = craftClasses.GetValue(loadRows[n], headers.Company);
                var craft = craftClasses.GetValue(loadRows[n], headers.MasterCraft);
                var @class = craftClasses.GetValue(loadRows[n], headers.CraftClass);

                // see if craft exist in 'load' array
                for (int i = 0; i <= load.GetUpperBound(0); i++)
                {
                    // if null reached, just add it
                    if (load[i, 0] != null)
                    {
                        exists = (string)load[i, 0] == co &&
                                 (string)load[i, 1] == craft &&
                                 (!craftsOnly ? load[i, 2] == @class : true);
                        if (exists) break; // dont' add it
                    }
                    else
                    {
                        exists = false; break; // add it
                    }
                }

                if (!exists)
                {
                    load[uniqueCraftCnt, 0] = co;
                    load[uniqueCraftCnt, 1] = craft;
                    load[uniqueCraftCnt, 2] = @class;
                    ++uniqueCraftCnt;
                }
            }
            // resize array to unique record count
            object[,] _load = (object[,])ResizeArray(load, new int[] { uniqueCraftCnt, colCnt });
            return _load;
        }

        internal static Array ResizeArray(Array arr, int[] newSizes)
        {
            if (newSizes.Length != arr.Rank)
                throw new ArgumentException("arr must have the same number of dimensions " +
                                            "as there are elements in newSizes", "newSizes in ResizeArray()");

            var temp = Array.CreateInstance(arr.GetType().GetElementType(), newSizes);
            int length = arr.Length <= temp.Length ? arr.Length : temp.Length;
            Array.ConstrainedCopy(arr, 0, temp, 0, length);
            return temp;
        }

        #endregion


        #region COLLECT CRAFT CLASS DATA FROM EXCEL

        /// <summary>
        /// Extract Craft Class info from Excel (Info and Notes) 
        /// </summary>
        /// <returns>success</returns>
        private bool _1_CraftClassesExtract(bool loadAllRows = false)
        {
            Excel.Range craftClasses = null;
            Excel.Range rng = null;
            success = false;

            try
            {
                ws = Globals.Ribbons.Ribbon1.MyDataSheet;

                // dynamically capture the craft class section of the user input rows
                craftClasses = ws.Names.Item("Info_and_Notes").RefersToRange;
                string fromColLetter = craftClasses.AddressLocal.Split('$')[1];
                string toColLetter   = craftClasses.AddressLocal.Split('$')[3];

                craftClasses = ws.get_Range(fromColLetter + ":" + toColLetter);

                // check required headers exist
                string[] headerLabels = { "Company", "Master Craft", "Craft Class", "Description", "EEO Class", "Notes - Sub-Trade", "Shop" };

                var headers = new System.Dynamic.ExpandoObject() as IDictionary<string, Object>; 

                // save header and column cordinal
                for (int i = 0; i <= headerLabels.Length - 1; i++)
                {
                    rng = craftClasses.Find(headerLabels[i], Type.Missing,
                                                            Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlPart,
                                                            Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                            Type.Missing, Type.Missing);
                    if (rng == null) throw new Exception("The active worksheet is not a valid Craft Class template.\n\n'" + headerLabels[i] + "' header not found. Check header rows.");

                    headers.Add(headerLabels[i].Replace(" ", "").Replace("-",""), rng.Column); 
                }
                this.headers = headers;
                headerRow = rng.Row;
                startRowData = Convert.ToUInt32(headerRow) + 1;

                if (ws.get_Range("B" + startRowData).Formula == "")
                    throw new Exception("User input must begin at row: " + startRowData);

                // get user input last row
                lastRow = ws.get_Range("C" + headerRow).End[Excel.XlDirection.xlDown].Row;

                // user input body
                craftClasses = ws.get_Range(fromColLetter + startRowData + ":" + toColLetter + lastRow);

                // user-input data present?
                workingRange = craftClasses.Find("*", Type.Missing,
                                                      Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                                      Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                      Type.Missing, Type.Missing);
                if (workingRange != null)
                {
                    // user-input missing fields ?
                    this.craftClasses = craftClasses.Value2;
                    var tuple = this.craftClasses.GetCraftClasses(ws, startRowData, loadAllRows: loadAllRows);

                    workingRange = tuple.cell;
                    loadRows = tuple.loadRows;

                    if (workingRange != null)
                    {
                        workingRange.Select();
                        MessageBox.Show(this, "Missing required field, see highlighted cell.", "Oops", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return false;
                    }
                    else if (loadRows.Count == 0)
                    {
                        MessageBox.Show(this, "There are no Craft Classes selected for loading.", "Oops", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        return false;
                    }
                }
                else //no data 
                {
                    craftClasses.Select();
                    return false;
                }

                //progCraftClasses.Maximum = info_notes_data.Rows.Count;
                //progCraftClasses.Visible = success = true;
                success = true;
            }
            catch (Exception) { throw; }
            finally
            {
                if (craftClasses != null) Marshal.ReleaseComObject(craftClasses); craftClasses = null;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
            return success;
        }

        /// <summary>
        /// Pay Rates extract from Excel
        /// </summary>
        /// <returns></returns>
        private bool Payrates_Extract()
        {
            Excel.Range payrates = null;
            success = false;

            try
            {
                // ws = Globals.Ribbons.Ribbon1.MyActiveSheet;

                // Get user-input range
                payrates = ws.Names.Item("Pay_Rates").RefersToRange;
                string fromColLetter = payrates.AddressLocal.Split('$')[1];
                string toColLetter = payrates.AddressLocal.Split('$')[3];

                payrates = ws.get_Range(fromColLetter + startRowData + ":" + toColLetter + lastRow);

                // is there any user-input data?
                workingRange = payrates.Find("*", Type.Missing,
                                        Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                        Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                        Type.Missing, Type.Missing);

                if (workingRange != null)
                {
                    this.payrates = ((object[,])payrates.Value2).Get2Pairs(craftClasses, loadRows, (uint)payrates.Column, startRowData);

                    if (this.payrates.Count == 0)
                    {
                        return false; // don't add to task
                    }
                }
                else //no data 
                {
                    return false; // don't add to task
                }

                //progPayrates.Maximum = this.payrates.Values.Sum((pairs) => pairs.Count);
                //progPayrates.Visible = success = true;
                success = true;

            }
            catch (Exception ex ) {
                if (ex.Data.Contains(3))
                {
                    uint[] rng = (uint[])ex.Data[3]; // bad cell row and col indexes
                    Excel.Range evilRange = ws.Cells[rng[0], rng[1]];
                    evilRange.Select();
                    Marshal.ReleaseComObject(evilRange); evilRange = null;
                }
                throw ex;
            }
            finally
            {
                if (payrates != null) Marshal.ReleaseComObject(payrates); payrates = null;
            }
            return success = true;
        }

        /// <summary>
        /// Add-on Earnings extract from Excel
        /// </summary>
        /// <returns>success</returns>
        private bool Addon_Earnings_Extract()
        {
            Excel.Range addonEarningsNamedRange = null;
            Excel.Range _addonEarnings = null;
            Excel.Range _addonEarnings_3pair_header = null;
            //Excel.Worksheet ws = null;
            Excel.Range rng = null;
            success = false;

            try
            {
                //ws = Globals.Ribbons.Ribbon1.MyActiveSheet;

                // Get Addon-Earnings section
                addonEarningsNamedRange = ws.Names.Item("Addon_Earnings").RefersToRange;
                string addonEarningsRC1 = addonEarningsNamedRange.AddressLocal;
                string fromColLetter = addonEarningsRC1.Split('$')[1];
                string toColLetter = addonEarningsRC1.Split('$')[3];
                //string fromColLetter = "BH";
                //string toColLetter   = "BZ";

                // 2-pairs range
                _addonEarnings = ws.get_Range(fromColLetter + headerRow + ":" + toColLetter + headerRow); // read headers

                _addonEarnings = _addonEarnings.Find("Variable", Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlPart,
                                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);

                string _toColLetter = _addonEarnings.AddressLocal.Split('$')[1]; // end of 2-pair section

                // 2-pairs body
                int _2pairCnt = ws.get_Range(_toColLetter + startRowData).Column - 1;
                rng = ws.Cells[lastRow, _2pairCnt]; // bottom-right corner of last cell
                _addonEarnings = ws.get_Range(fromColLetter + startRowData, rng);

                //_2pairCnt = _addonEarnings.SpecialCells(Excel.XlCellType.xlCellTypeConstants).Count;

                // any user-input data?
                workingRange = _addonEarnings.Find("*", Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);
                if (workingRange != null)
                {
                    addonEarnings_2pairs = ((object[,])_addonEarnings.Value2).Get2Pairs(craftClasses, loadRows, (uint)addonEarningsNamedRange.Column, startRowData);
                }

                // 3-pairs body
                fromColLetter   = _toColLetter;
                _addonEarnings  = ws.get_Range(fromColLetter + startRowData + ":" + toColLetter + lastRow);

                // 3-pairs header 
                _addonEarnings_3pair_header = ws.get_Range(fromColLetter + headerRow + ":" + toColLetter + headerRow);

                // any user-input data?
                workingRange = _addonEarnings.Find("*", Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);
                if (workingRange != null)
                {
                    addonEarnings_3pairs = ((object[,])_addonEarnings.Value2).Get3Pairs(_addonEarnings_3pair_header, craftClasses, loadRows, (uint)_addonEarnings.Column, startRowData); //headers for identifying 'Variable' columns
                    //variableCnt = tuple.variableCnt;
                    //addonEarnings_3pairs = tuple._3pairs;
                }

                if (addonEarnings_2pairs == null && addonEarnings_3pairs == null || addonEarnings_2pairs?.Count == 0 && addonEarnings_3pairs?.Count == 0) return false; // continue to next section

                // record count to be staged
                //_2pairCnt = addonEarnings_2pairs.Values.Sum((pairs) => pairs.Count);
                //int _3pairCnt = addonEarnings_3pairs.Values.Sum((pairs) => pairs.Count); //(_3pairCnt - (addonEarnings_3pairs.Count * variableCnt)) / 2;

                //progAddonEarnings.Maximum = _2pairCnt + _3pairCnt;
                //progAddonEarnings.Visible = success = true;
                success = true;
            }
            catch (Exception ex)
            {
                if (ex.Data.Contains(3))
                {
                    uint[] _rng = (uint[])ex.Data[3]; // bad cell row and col indexes
                    Excel.Range evilRange = ws.Cells[_rng[0], _rng[1]];
                    evilRange.Select();
                    Marshal.ReleaseComObject(evilRange); evilRange = null;
                }
                throw ex;
            }
            finally
            {
                if (_addonEarnings_3pair_header != null) Marshal.ReleaseComObject(_addonEarnings_3pair_header); _addonEarnings_3pair_header = null;
                if (_addonEarnings != null) Marshal.ReleaseComObject(_addonEarnings); _addonEarnings = null;
                if (addonEarningsNamedRange != null) Marshal.ReleaseComObject(addonEarningsNamedRange); addonEarningsNamedRange = null;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
            return success;
        }

        /// <summary>
        /// Add-on Earnings extract from Excel
        /// </summary>
        /// <returns>success</returns>
        private bool Deductions_Liabilities_Extract()
        {
            Excel.Range dednsLiabsNamedRange = null;
            Excel.Range _dednsLiabs = null;
            Excel.Range _dednsLiabs_3pair_header = null;
            //Excel.Worksheet ws = null;
            Excel.Range rng = null;
            success = false;

            try
            {
                //ws = Globals.Ribbons.Ribbon1.MyActiveSheet;

                dednsLiabsNamedRange = ws.Names.Item("Dedns_Liabs").RefersToRange;
                string dednsLiabsRC1 = dednsLiabsNamedRange.AddressLocal;
                string fromColLetter = dednsLiabsRC1.Split('$')[1];
                string toColLetter = dednsLiabsRC1.Split('$')[3];
                //string fromColLetter = "CA";
                //string toColLetter   = "EZ";

                // 2-pairs
                _dednsLiabs = ws.get_Range(fromColLetter + headerRow + ":" + toColLetter + headerRow); // read headers

                _dednsLiabs = _dednsLiabs.Find("Variable", Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlPart,
                                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);

                string _toColLetter = _dednsLiabs.AddressLocal.Split('$')[1]; // end of 2-pairs

                // 2-pairs body
                int _2pairCnt = ws.get_Range(_toColLetter + startRowData).Column - 1;
                rng = ws.Cells[lastRow, _2pairCnt];
                _dednsLiabs = ws.get_Range(fromColLetter + startRowData, rng);

                //_2pairCnt = _dednsLiabs.SpecialCells(Excel.XlCellType.xlCellTypeConstants).Count;

                // any user-input data?
                workingRange = _dednsLiabs.Find("*", Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);
                if (workingRange != null)
                {
                    dednsLiabs_2pairs = ((object[,])_dednsLiabs.Value2).Get2Pairs(craftClasses, loadRows, (uint)dednsLiabsNamedRange.Column, startRowData);
                }

                // 3-pair headers
                fromColLetter = _toColLetter;
                _dednsLiabs_3pair_header = ws.get_Range(fromColLetter + headerRow + ":" + toColLetter + headerRow);

                // 3-pair body
                _dednsLiabs = ws.get_Range(fromColLetter + startRowData + ":" + toColLetter + lastRow);

                // user-input data?
                workingRange = _dednsLiabs.Find("*", Type.Missing,
                                                Excel.XlFindLookIn.xlValues, Excel.XlLookAt.xlWhole,
                                                Excel.XlSearchOrder.xlByRows, Excel.XlSearchDirection.xlNext, false,
                                                Type.Missing, Type.Missing);
                if (workingRange != null)
                {
                    dednsLiabs_3pairs = ((object[,])_dednsLiabs.Value2).Get3Pairs(_dednsLiabs_3pair_header, craftClasses, loadRows, (uint)_dednsLiabs.Column, startRowData); //headers for identifying 'Variable' columns
                    //dednsLiabs_3pairs = tuple._3pairs;
                    //varibleCnt = tuple.variableCnt;
                }

                if (dednsLiabs_2pairs == null && dednsLiabs_3pairs == null || dednsLiabs_2pairs.Count == 0 && dednsLiabs_3pairs.Count == 0) return false; // continue to next section

                // records count to be inserted
                //_2pairCnt = dednsLiabs_2pairs.Values.Sum((pairs) => pairs.Count);
                //int _3pairCnt = dednsLiabs_3pairs.Values.Sum((pairs) => pairs.Count);  //(_3pairCnt - (dednsLiabs_3pairs.Count * varibleCnt)) / 2;

                //progDednsLiabs.Maximum = _2pairCnt + _3pairCnt;
                //progDednsLiabs.Visible = success = true;
                success = true;
            }
            catch (Exception ex)
            {
                if (ex.Data.Contains(3))
                {
                    uint[] _rng = (uint[])ex.Data[3]; // bad cell row and col indexes
                    Excel.Range evilRange = ws.Cells[_rng[0], _rng[1]];
                    evilRange.Select();
                    Marshal.ReleaseComObject(evilRange); evilRange = null;
                }
                throw ex;
            }
            finally
            {
                if (_dednsLiabs_3pair_header != null) Marshal.ReleaseComObject(_dednsLiabs_3pair_header); _dednsLiabs_3pair_header = null;
                if (_dednsLiabs != null) Marshal.ReleaseComObject(_dednsLiabs); _dednsLiabs = null;
                if (dednsLiabsNamedRange != null) Marshal.ReleaseComObject(dednsLiabsNamedRange); dednsLiabsNamedRange = null;
                if (rng != null) Marshal.ReleaseComObject(rng); rng = null;
            }
            return success;
        }

        #endregion


        #region GENERATE VARIANCE REPORT

        /// <summary>
        /// Variance-check all rows irrespective of 'Load Y/N' filter
        /// </summary>
        public void CheckViewpointVariances()
        {
            Office.Ribbon.RibbonButton btn = Globals.Ribbons.Ribbon1.btnCheckVariances;

            if (btn.Label == "Check Variances")
            {
                try
                {
                    string msgCaption = "[Preparing Data]";
                    btn.Label = "Cancel";

                    lblProcessing.Text = msgCaption;
                    lblProcessing.Refresh();

                    if (!_1_CraftClassesExtract(loadAllRows: true)) // checks all rows irrespective of column A's 'Load Y/N' filter
                    {
                        lblProcessing.Text = "[Status]";
                        btn.Label = "Check Variances";
                        return;
                    }

                    DeleteErrTab();
                    DeleteVarianceTabs();
                    varianceReports?.Clear();

                    // For Task.Run work properly around an MS BUG: http://stackoverflow.com/questions/32455111/hooked-events-outlook-vsto-continuing-job-on-main-thread
                    System.Threading.SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());
                    
                    // gather all tasks that need to be run
                    List<Task> tasks = new List<Task>();
                    cancelToken = new CancellationTokenSource();

                    if (craftClasses != null && loadRows.Count > 0 )
                    {
                        // create user batch
                        if (batchId == null) batchId = Batch.CreateBatch();
                        lblBatch.Text = batchId.ToString();
                        lblBatch.Refresh();

                        // Craft Classes
                        if (!craftClassesInserted)
                        {
                            tasks.Add(new Task(() =>
                            {
                                craftClassesInserted = Stage.CraftClasses(batchId, craftClasses, headers, loadRows, cancelToken) > 0;
                            }));
                        }

                        // Payrates
                        if (!payratesInserted)
                        {
                            if (Payrates_Extract()) tasks.Add(new Task(() =>
                            {
                                payratesInserted = Stage.Payrates(batchId, craftClasses, payrates, headers, cancelToken) > 0;
                            }));
                        }

                        // Addon Earnings
                        if (!addonEarningsInserted)
                        {
                            if (Addon_Earnings_Extract()) tasks.Add(new Task(() =>
                            {
                                addonEarningsInserted = Stage.AddonEarnings(batchId, craftClasses, addonEarnings_2pairs, addonEarnings_3pairs, headers, cancelToken) > 0;
                            }));
                        }

                        // Dedns & Liabs 
                        if (!dednsLaibsInserted)
                        {
                            if (Deductions_Liabilities_Extract()) tasks.Add(new Task(() =>
                            {
                                dednsLaibsInserted = Stage.DednsLiabs(batchId, craftClasses, dednsLiabs_2pairs, dednsLiabs_3pairs, headers, cancelToken) > 0;
                            }));
                        }

                        //IProgress<string> timer = new Progress<string>(elapsed => { MessageBox.Show(this, elapsed, lblProcessing.Text); });
                        //Stopwatch sw = Stopwatch.StartNew();

                        // is there any data collected on the staging tables ?
                        if (!craftClassesInserted || !payratesInserted || !addonEarningsInserted || !dednsLaibsInserted & !batchProcessed)
                        {
                            msgCaption = "[Preparing Data]";
                            // batch progress / status
                            IProgress<string> processingLbl = new Progress<string>(caption =>
                            {
                                lblProcessing.Text = msgCaption = caption;
                            });

                            IProgress<Dictionary<string, List<dynamic>>> _success = new Progress<Dictionary<string, List<dynamic>>>(failedValidationTables =>
                            {
                                ShowValidationErrReports(failedValidationTables);
                                string msg = lblProcessing.Text == "Failed Validation" ? "Failed Validation" : "No variances found!";
                                string title = "Failed";

                                if (msg == "No variances found!")
                                {
                                    // passed validation so batch was checked
                                    lblProcessing.Text = "[Check Completed]";
                                    title = "Success!";
                                }
                                btn.Label = "Check Variances";

                                if (failedValidationTables.Any((table) => table.Value?.Count > 0))
                                {
                                    MessageBox.Show(null, "Craft Class variance check completed but there were errors.\n\n" +
                                                          "Craft Classes with errors are not represented in the variance reports. See error report.", "Success with errors", MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                                }
                                else
                                {
                                    // determine singular or plurar
                                    int reportCnt = 0;

                                    if (varianceReports != null)
                                    {
                                        reportCnt = varianceReports.First().Count((table) => table.Value.Count > 0); // First() = 4 tables container
                                    }

                                    MessageBox.Show(null, (reportCnt > 0 ? ((reportCnt > 1) ? "Craft Class variance reports are ready!" : "Craft Class variance report is ready!")
                                                                                            : msg
                                                            ), title, MessageBoxButtons.OK, MessageBoxIcon.Information);
                                }
                                ResetFlags();
                                return;
                            });

                            IProgress<List<Dictionary<string, List<dynamic>>>> _diffs = new Progress<List<Dictionary<string, List<dynamic>>>>(tableDiffs =>
                            {
                                ShowVarianceReport(tableDiffs);
                                return;
                            });

                            IProgress<object[]> _failure = new Progress<object[]>(fail =>
                            {
                                Exception ex = null;
                                if (fail != null)
                                {
                                    ex = (Exception)fail[0];
                                    Dictionary<string, List<dynamic>> failedValidationTables = (Dictionary<string, List<dynamic>>)fail[1];
                                    ShowValidationErrReports(failedValidationTables);
                                }

                                MessageBoxIcon iconType = MessageBoxIcon.Exclamation;
                                string errmsg = null;
                                if (ex != null)
                                {
                                    lblProcessing.Text = "[Check Completed]";
                                    lblProcessing.Refresh();
                                    msgCaption = "[Check Completed]";
                                    errmsg = "Check completed succesfully but..\n\n" + ex.Message;
                                }
                                else
                                {
                                    if (!cancelToken.IsCancellationRequested)
                                    {
                                        msgCaption = msgCaption + " - " + ex?.Data[0];
                                        lblProcessing.Text = "[Failed Check]";
                                        lblProcessing.Refresh();
                                        iconType = MessageBoxIcon.Error;
                                        btn.Label = "Check Variances";
                                    }
                                    else
                                    {
                                        lblProcessing.Text = msgCaption = "[Check Cancelled]";
                                        lblProcessing.Refresh();
                                    }

                                    if (ex != null)
                                    {// a diff check sp
                                        errmsg = ex.Message.Contains("cancelled") ? "Operation Cancelled" : ex.Message;
                                        //errmsg = ex.Message.Contains("cancelled", StringComparison.OrdinalIgnoreCase) ? "Operation Cancelled" : ex.Message;
                                    }
                                    else
                                    {// 1 of the 4 staging tasks
                                        errmsg = "Operation Cancelled";
                                    }
                                    ResetFlags();
                                }
                                MessageBox.Show(this, errmsg, msgCaption, MessageBoxButtons.OK, iconType);
                                return;
                            });

                            // Run tasks in parallel milti-thread
                            Task.Run(() =>
                            {
                                //sw = Stopwatch.StartNew();
                                Parallel.ForEach(tasks, task => task.Start());
                                Task.WaitAll(tasks.ToArray());
                                //timer.Report(String.Format("Time elapsed: {0:hh\\:mm\\:ss}", sw.Elapsed.ToString()));

                                if (cancelToken.Token.IsCancellationRequested)
                                {
                                    _failure.Report(null);
                                    return;
                                }

                                if (craftClassesInserted || payratesInserted || addonEarningsInserted || dednsLaibsInserted && !batchProcessed)
                                {
                                    processingLbl.Report("[Checking Variances...]");
                                    Task.Run(() =>
                                    {
                                        Batch.CancelToken = cancelToken;
                                        try
                                        {
                                            bool validated = Batch.Validate(batchId);
                                            processingLbl.Report("[Please wait...]");
                                            if (validated)
                                            {
                                                varianceReports = GetViewpointVariances();
                                                _diffs.Report(varianceReports);
                                            }
                                            else
                                            {
                                                processingLbl.Report("Failed Validation");
                                            }
                                            _success.Report(GetValidationErrsFromViewpoint());
                                        }
                                        catch (Exception ex)
                                        {
                                            processingLbl.Report("[Please wait...]");
                                            Dictionary<string, List<dynamic>> failedValidationTables = GetValidationErrsFromViewpoint();
                                            _failure.Report(new object[] { ex, failedValidationTables });
                                        }
                                    });
                                }
                                else
                                {
                                    _failure.Report(null); // no data staged
                                }
                            });
                        }
                    }
                    else
                    {
                        throw new Exception("No records selected for loading. Set the 'Load Y/N' filter.");
                    }
                }
                catch (Exception ex)
                {
                    HelperUI.RenderON();
                    lblProcessing.Text = "[Failure!]";
                    if (ex.Data.Count == 0) ex.Data.Add(0, "CheckVariances");
                    btn.Label = "Check Variances";
                    ResetFlags();
                    ShowErr(ex);
                }
            }
            else if (btn.Label == "Cancel")
            {
                btn.Enabled = false;
                btn.Label = "Cancelling...";
                cancelToken.Cancel();
                btn.Enabled = true;
                btn.Label = "Check Variances";
                lblProcessing.Text = "[Cancelled Check]";
            }
        }

        private List<Dictionary<string, List<dynamic>>> GetViewpointVariances()
        {
            List<dynamic> craftClassesTable = null;
            List<dynamic> payratesDiffTable = null;
            List<dynamic> addonEarningsDiffTable = null;
            List<dynamic> dednsLiabsDiffTable = null;
            //List<dynamic> payratesNotInVPTable = null;
            //List<dynamic> addonEarningsNotInVPTable = null;
            //List<dynamic> dednsLiabsNotInVPTable = null;
            //List<Dictionary<string, List<dynamic>>> tables = new List<Dictionary<string, List<dynamic>>>();
            varianceReports = new List<Dictionary<string, List<dynamic>>>();

            List<Task> tasks = new List<Task>
            {
                new Task(() =>
                {
                    craftClassesTable = Batch.CraftClassDiff(batchId);
                }),

                new Task(() =>
                {
                    payratesDiffTable = Batch.PayratesDiff(batchId);
                    //payratesNotInVPTable = Batch.PayratesNotInVP(batchId);
                }),

                new Task(() =>
                {
                    addonEarningsDiffTable = Batch.AddonEarningsDiff(batchId);
                    //addonEarningsNotInVPTable = Batch.AddonEarningsNotInVP(batchId);
                }),

                new Task(() =>
                {
                    dednsLiabsDiffTable = Batch.DednsLiabsDiff(batchId);
                    //dednsLiabsNotInVPTable = Batch.DednsLiabsNotInVP(batchId);
                }),
            };

            Parallel.ForEach(tasks, task => task.Start());

            Task.WaitAll(tasks.ToArray());

            Dictionary<string, List<dynamic>> tableDiffs = new Dictionary<string, List<dynamic>>
            {
                { "Craft Class Variances",            craftClassesTable },
                { "Pay Rate Variances",               payratesDiffTable },
                { "AddOn Earnings Variances",         addonEarningsDiffTable },
                { "Deductions and Liabs Variances" ,  dednsLiabsDiffTable }
            };

            varianceReports.Add(tableDiffs);

            // ** ALLOWS A SECOND TABLE IN THE SHEET **
            //Dictionary<string, List<dynamic>> tableNotInVP = new Dictionary<string, List<dynamic>>
            //{
            //    { "Pay Rates Not In Viewpoint",      payratesNotInVPTable },
            //    { "AddOn Earnings Not In Viewpoint", addonEarningsNotInVPTable },
            //    { "Deductions and Liabs Not In VP",  dednsLiabsNotInVPTable }
            //};
            //tables.Add(tableNotInVP);

            return varianceReports;
        }

        private void ShowVarianceReport(List<Dictionary<string, List<dynamic>>> tables)
        {
            Excel.Worksheet ws = null;
            Excel.ListObject xlTable = null;

            try
            {
                foreach (var dataset in tables)
                {
                    if (dataset.Any((table) => table.Value?.Count > 0))
                    {
                        foreach (var table in dataset)
                        {
                            if (table.Value?.Count > 0)
                            {

                                // generate sheet name from table name
                                // NOTE: don't create sheet for tables in tableNotInVP.  Place tables in tableDiffs tabs
                                int idxOfNotInVP = table.Key.IndexOf("s Not");
                                string sheetName = idxOfNotInVP == -1 ? table.Key : table.Key.Substring(0, idxOfNotInVP);
                                ws = HelperUI.GetSheet(sheetName, false);

                                if (ws == null)
                                {
                                    // Create new sheet
                                    
                                    //ws = Globals.ThisAddIn.Application.Sheets.Add(After: (Excel.Worksheet)Globals.ThisAddIn.Application.ActiveSheet);
                                    ws = Globals.Ribbons.Ribbon1.MyActiveWorkbook.Sheets.Add(After: Globals.Ribbons.Ribbon1.MyActiveWorkbook.ActiveSheet);
                                    if (ws != null)
                                    {
                                        HelperUI.RenderOFF();

                                        //ws.get_Range("A2:I2").Merge();
                                        ws.get_Range("A2").Formula = table.Key + ": Viewpoint vs Excel";
                                        ws.get_Range("A2").Font.Size = HelperUI.TwentyFontSizePageHeader;
                                        ws.get_Range("A2").Font.Bold = true;
                                        ws.get_Range("A2").Font.Name = "Calibri";
                                        ws.get_Range("A2").EntireRow.RowHeight = 36;
                                        ws.get_Range("A2").HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                                        ws.get_Range("A2").VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                                        ws.Name = table.Key.Length > 31 ? table.Key.Substring(0, 31) : table.Key; // 31 = Excel's max tab name lenth
                                        ws.Application.ActiveWindow.DisplayGridlines = false;
                                    }
                                }

                                if (ws != null)
                                {
                                    ws.Activate();

                                    List<dynamic> _table = table.Value;
                                    string tableName = table.Key.Replace(" ", "_").Replace("-", "_");

                                    // add'l column formats also in BuildTable
                                    xlTable = SheetBuilderDynamic.BuildTable(ws, _table, tableName, offsetFromLastUsedCell: 2, bandedRows: true);

                                    if (table.Key == "Craft Class Variances")
                                    {
                                        xlTable.ListColumns["Description"].DataBodyRange.EntireColumn.AutoFit();
                                        xlTable.ListColumns["Notes"].DataBodyRange.EntireColumn.AutoFit();
                                        xlTable.ListColumns["udShopYN"].DataBodyRange.EntireColumn.ColumnWidth = 8.14;
                                    }
                                    //xlTable.ListColumns["Src"].DataBodyRange.EntireColumn.AutoFit();
                                    xlTable.ListColumns["Src"].DataBodyRange.EntireColumn.ColumnWidth = 10.57;
                                    xlTable.ListColumns["Co"].DataBodyRange.EntireColumn.AutoFit();
                                    xlTable.ShowTableStyleRowStripes = true;

                                    uint tableId = table.Key.Contains("Variances") || table.Key.Contains("Diffs") ? (uint)1 : 2;

                                    HelperUI.MergeLabel(ws, "Src", xlTable.ListColumns[xlTable.ListColumns.Count].Name, table.Key, tableId, offsetRowUpFromTableHeader: 1, horizAlign: Excel.XlHAlign.xlHAlignLeft);

                                    ws.get_Range("A3").Activate();
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "ShowVarianceReport");
                Globals.Ribbons.Ribbon1.btnCheckVariances.Label = "Check Variances";
                //progBatchProcess.Value = progBatchProcess.Maximum;
                ResetFlags();
                ShowErr(ex);
            }
            finally
            {
                HelperUI.RenderON();
                if (ws != null) Marshal.ReleaseComObject(ws);
                //if (xlTable != null) Marshal.ReleaseComObject(xlTable);
            }

        }

        #endregion


        #region GENERATE VALIDATION ERROR REPORTS

        /// <summary>
        /// Checks for failed validations from Viewpoint
        /// </summary>
        /// <remarks>Multi-threaded tasks</remarks>
        /// <returns>failed validation reports</returns>
        private Dictionary<string, List<dynamic>> GetValidationErrsFromViewpoint()
        {
            List<dynamic> craftClassesTable = null;
            List<dynamic> payratesTable = null;
            List<dynamic> dednsLiabsTable = null;
            List<dynamic> addonEarningsTable = null;

            List<Task> tasks = new List<Task>
            {
                new Task(() =>
                {
                    craftClassesTable = Batch.GetCraftClassErrors(batchId);
                }),

                new Task(() =>
                {
                    payratesTable = Batch.GetPayratesErrors(batchId);
                }),

                new Task(() =>
                {
                    dednsLiabsTable = Batch.GetDednsLiabsErrors(batchId);
                }),

                new Task(() =>
                {
                    addonEarningsTable = Batch.GetAddonEarningsErrors(batchId);
                })
            };

            Parallel.ForEach(tasks, task => task.Start());

            Task.WaitAll(tasks.ToArray());

            Dictionary<string, List<dynamic>> failedValidationTables = new Dictionary<string, List<dynamic>>
            {
                { "Craft Classes",              craftClassesTable },
                { "Pay Rates",                  payratesTable },
                { "Deductions and Liabilities", dednsLiabsTable },
                { "Add-On Earnings",            addonEarningsTable }
            };

            return failedValidationTables;
        }

        private void ShowValidationErrReports(Dictionary<string, List<dynamic>> stagingTables)
        {
            // only create validation report if there are any errors
            if (stagingTables.Any((table) => table.Value?.Count > 0))
            {
                Excel.Worksheet ws = null;
                Excel.ListObject xlTable = null;
                try
                {
                    ws = Globals.Ribbons.Ribbon1.MyActiveWorkbook.Sheets.Add(After: Globals.Ribbons.Ribbon1.MyActiveWorkbook.ActiveSheet);
                    if (ws != null)
                    {
                        HelperUI.RenderOFF();

                        ws.get_Range("A1:I1").Merge();
                        ws.get_Range("A1").Formula = "Failed Validation:";
                        ws.get_Range("A1").Font.Size = HelperUI.TwentyFontSizePageHeader;
                        ws.get_Range("A1").Font.Bold = true;
                        ws.get_Range("A1").Font.Name = "Calibri";
                        ws.get_Range("A1").EntireRow.RowHeight = 36;
                        ws.get_Range("A1").HorizontalAlignment = Excel.XlHAlign.xlHAlignLeft;
                        ws.get_Range("A1").VerticalAlignment = Excel.XlVAlign.xlVAlignCenter;
                        ws.get_Range("A3").Activate();
                        ws.Name = "Errors Batch " + batchId;
                        ws.Application.ActiveWindow.DisplayGridlines = false;

                        uint tableId = 0;
                        foreach (var table in stagingTables)
                        {
                            if (table.Value?.Count > 0)
                            {
                                ++tableId;
                                List<dynamic> _table = table.Value;
                                string tableName = table.Key.Replace(" ", "_").Replace("-", "_");
                                xlTable = SheetBuilderDynamic.BuildTable(ws, _table, tableName, tableId == 1 ? 2 : 3);
                                xlTable.ListColumns["Errmsg"].DataBodyRange.Interior.Color = HelperUI.RedNegColor;
                                xlTable.ListColumns["Errmsg"].DataBodyRange.EntireColumn.AutoFit();
                                HelperUI.MergeLabel(ws, "Co", "ErrDate", table.Key, tableId, 1, horizAlign: Excel.XlHAlign.xlHAlignLeft);
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    if (ex.Data.Count == 0) ex.Data.Add(0, "ShowValidationErrs");
                    Globals.Ribbons.Ribbon1.btnUpdate.Label = "Update Rates";
                    //progBatchProcess.Value = progBatchProcess.Maximum;
                    ResetFlags();
                    ShowErr(ex);
                }
                finally
                {
                    HelperUI.RenderON();
                    if (ws != null) Marshal.ReleaseComObject(ws); ws = null;
                    if (xlTable != null) Marshal.ReleaseComObject(xlTable); xlTable = null;
                }
            }
        }

        private void ShowErr(Exception ex)
        {
            string msg = null;
            MessageBoxIcon icon = MessageBoxIcon.Error;
            if (ex.Data.Count >= 2)
            {
                msg = ex.Data[1].ToString();
                icon = MessageBoxIcon.Information;
            }
            else
            {
                msg = ex.Message;
            }

            if (ex.Data.Contains(3)) icon = MessageBoxIcon.Error;

            MessageBox.Show(null, msg, ex.Data[0].ToString(), MessageBoxButtons.OK, icon);
        }

        #endregion


        #region NEW BATCH & CLEAN UP

        //private void ClearTextboxesProgressBars()
        //{
        //    lblCraftClassesCnt.BackColor = default(System.Drawing.Color);
        //    lblPayratesCnt.BackColor = default(System.Drawing.Color);
        //    lblAddonEarningsCnt.BackColor = default(System.Drawing.Color);
        //    lblDednsLiabsCnt.BackColor = default(System.Drawing.Color);
        //    lblCraftClassesCnt.Text = "";
        //    lblPayratesCnt.Text = "";
        //    lblAddonEarningsCnt.Text = "";
        //    lblDednsLiabsCnt.Text = "";
        //    lblTotal.Text = "";
        //    lblListNoUpdates.Text = "";
        //    progCraftClasses.Maximum = progCraftClasses.Value = 0;
        //    progPayrates.Maximum = progPayrates.Value = 0;
        //    progAddonEarnings.Maximum = progAddonEarnings.Value = 0;
        //    progDednsLiabs.Maximum = progDednsLiabs.Value = 0;
        //    progBatchProcess.Maximum = 1;
        //    progBatchProcess.Value = 0;
        //}

        private void DeleteVarianceTabs()
        {
            try
            {
                // clear out data structures
                //payrates?.Clear();
                //addonEarnings_2pairs?.Clear();
                //addonEarnings_3pairs?.Clear();
                //dednsLiabs_2pairs?.Clear();
                //dednsLiabs_3pairs?.Clear();

                // delete variance tabs
                Excel.Workbook wb = ws?.Parent ?? Globals.ThisAddIn.Application.ActiveWorkbook;

                Globals.ThisAddIn.Application.DisplayAlerts = false;

                foreach (Excel.Worksheet ws in wb.Worksheets)
                {
                    if (ws.Name.Contains(" Variances") && ws.get_Range("A2").Formula.Contains(": Viewpoint vs Excel")) ws.Delete();
                }

                Globals.ThisAddIn.Application.DisplayAlerts = true;
            }
            catch (Exception ex)
            {
                errOut(ex);
            }
        }

        private void ResetFlags()
        {
            success = false;
            batchId = null;
            craftClasses = null;
            payratesInserted = false;
            craftClassesInserted = false;
            dednsLaibsInserted = false;
            addonEarningsInserted = false;
            batchProcessed = false;
            //lblCraftClassesCnt.BackColor = System.Drawing.Color.LightGray;
            //lblPayratesCnt.BackColor = System.Drawing.Color.LightGray;
            //lblAddonEarningsCnt.BackColor = System.Drawing.Color.LightGray;
            //lblDednsLiabsCnt.BackColor = System.Drawing.Color.LightGray;
        }

        private void DeleteErrTab()
        {
            try
            {
                Globals.ThisAddIn.Application.DisplayAlerts = false;
                HelperUI.GetSheet("Errors Batch ", false)?.Delete();
            }
            catch (Exception ex)
            {
                if (ex.Data.Count == 0) ex.Data.Add(0, "DeleteErrTab");
                ShowErr(ex);
            }
            finally
            {
                Globals.ThisAddIn.Application.DisplayAlerts = true;
            }
        }

        //private void DeleteCraftsToBeLoadedTab()
        //{
        //    try
        //    {
        //        Globals.ThisAddIn.Application.DisplayAlerts = false;
        //        HelperUI.GetSheet("Crafts to be udpated")?.Delete();
        //    }
        //    catch (Exception ex)
        //    {
        //        if (ex.Data.Count == 0) ex.Data.Add(0, "DeleteErrTab");
        //        ShowErr(ex);
        //    }
        //    finally
        //    {
        //        Globals.ThisAddIn.Application.DisplayAlerts = true;
        //    }
        //}

        #endregion
        

        private Dictionary<int, string> ClassColumnValues { get; set; }

        /// <summary>
        /// Exclude rows with 'N' load filter from Variance and Validation reports only on 'Update Rates'
        /// </summary>
        /// <param name="varianceReports"></param>
        /// <remarks>Search method used does not require sheet to be active so user can roam other worksheets meanwhile processing completes</remarks>
        private void ExcludeLoadFilterN(List<Dictionary<string, List<dynamic>>> varianceReports)
        {
            //Excel.Range found = null;

            try
            {
                byte co;
                string craft;
                string @class;

                // any variances ? 
                if (varianceReports.Any((table) => table.Values?.Count > 0))
                {
                    // yes, loop thru variance tables
                    foreach (IDictionary<string, List<dynamic>> varianceTables in varianceReports)
                    {
                        foreach (List<dynamic> table in varianceTables.Values)
                        {
                            // loop clone to potentially remove items in the original
                            List<dynamic> tmptable = new List<dynamic>(table);

                            // search match method below does not require sheet to be active (user can roam other worksheets) 
                            foreach (dynamic row in tmptable)
                            {
                                co = row.Co.Value;
                                craft = row.Craft.Value;
                                @class = row.Class.Value;

                                var found = ClassColumnValues.Where(kv => kv.Value == @class);

                                if (found.Count() > 0)
                                {
                                    var foundRow = found.First().Key + headerRow;

                                    // Company / Craft match variance Class ?
                                    if (Convert.ToByte(ws.Cells[foundRow, headers.Company].Value) == co &&
                                                      ws.Cells[foundRow, headers.MasterCraft].Text == craft)
                                    {
                                        if (ws.get_Range("A" + foundRow).Formula == "N")
                                        {
                                            table.Remove(row);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                errOut(ex);
            }
        }

        /// <summary>
        /// Get the 'Class' column values from Excel for faster search
        /// </summary>
        /// <returns>The 'Class' column values</returns>
        /// <remarks>Dependent of ArrayExtensions.Cast()</remarks>
        private Dictionary<int, string> GetClassColumn()
        {
            Excel.Range start = null;
            Excel.Range end = null;
            Excel.Range xlClassCol = null;

            try
            {
                ws = Globals.Ribbons.Ribbon1.MyDataSheet;

                start = ws.Cells[startRowData, headers.CraftClass];
                end = ws.Cells[lastRow, headers.CraftClass];

                xlClassCol = ws.get_Range(start, end);

                if (xlClassCol.Value2.GetType() == typeof(object[,]))
                {
                    // multiple lines
                    object[,] clasCol = xlClassCol.Value2;
                    return clasCol.Cast();
                }
                else // single line
                {
                    Dictionary<int, string> clasCol = new Dictionary<int, string>
                    {
                        { xlClassCol.Row, xlClassCol.Value }
                    };
                    return clasCol;
                }
            }
            catch (Exception)
            {
                throw;
            }
            finally
            {
                if (start != null) Marshal.ReleaseComObject(start);
                if (end != null) Marshal.ReleaseComObject(end);
                if (xlClassCol != null) Marshal.ReleaseComObject(xlClassCol);
            }
        }

        /// <summary>
        /// Flip all successful updates 'Load Y/N' filter to N but leaves any Variance and erroneous rows as Y.
        /// </summary>
        /// <param name="failedValidationTables"></param>
        /// <remarks>Search method used does not require sheet to be active so user can roam other worksheets meanwhile processing completes</remarks>
        private void FlipSuccessUpdatesToLoadFilterN(Dictionary<string, List<dynamic>>failedValidationTables)
        {
            Excel.Range LoadFilterYN = null;

            try
            {
                //ws.AutoFilterMode = false;
                LoadFilterYN = ws.get_Range("A" + startRowData + ":A" + lastRow);
                LoadFilterYN.set_Value(Excel.XlRangeValueDataType.xlRangeValueDefault, "N");

                byte co;
                string craft;
                string @class;

                // any errors ? 
                if (failedValidationTables.Any((table) => table.Value?.Count > 0))
                {
                    // if so.. get the failed Craft Classes
                    List<dynamic> badCraftClass = failedValidationTables.FirstOrDefault((table) => table.Key == "Craft Classes").Value;

                    foreach (dynamic row in badCraftClass)
                    {
                        co = row.Co.Value;
                        craft = row.Craft.Value;
                        @class = row.Class.Value; // no duplicates can exist, else only 1st found gets updated

                        // earch Class column for failed Class
                        var found = ClassColumnValues.Where(kv => kv.Value == @class);

                        if (found.Count() > 0)
                        {
                            var foundRow = found.First().Key + headerRow;

                            // Company / Craft match variance Class ?
                            if (Convert.ToByte(ws.Cells[foundRow, headers.Company].Value) == co &&
                                              ws.Cells[foundRow, headers.MasterCraft].Text == craft)
                            {
                                ws.get_Range("A" + foundRow).Formula = "Y"; // flip it for loading
                            }
                        }
                    }
                }

                // any variances ? 
                if (varianceReports.Any((table) => table.Values?.Count > 0))
                {
                    // if so.. loop thru variance tables
                    foreach (IDictionary<string, List<dynamic>> varianceTables in varianceReports)
                    {
                        foreach (List<dynamic> table in varianceTables.Values)
                        {
                            foreach (dynamic row in table)
                            {
                                co = row.Co.Value;
                                craft = row.Craft.Value;
                                @class = row.Class.Value;

                                // search Class column for variance Class
                                var found = ClassColumnValues.Where(kv => kv.Value == @class);

                                if (found.Count() > 0)
                                {
                                    var foundRow = found.First().Key + headerRow;

                                    // Company / Craft match variance Class ?
                                    if (Convert.ToByte(ws.Cells[foundRow, headers.Company].Value) == co &&
                                                      ws.Cells[foundRow, headers.MasterCraft].Text == craft)
                                    {
                                        ws.get_Range("A" + foundRow).Formula = "Y"; // flip it for loading
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                errOut(ex);
            }
            finally
            {
                if (LoadFilterYN != null) Marshal.ReleaseComObject(LoadFilterYN);
            }
        }






        //private void tmrFadeLabel_Tick(object sender, EventArgs e)
        //{
        //    int fadingSpeed = 3;
        //    lblListNoUpdates.ForeColor = System.Drawing.Color.FromArgb(lblListNoUpdates.ForeColor.R + fadingSpeed, lblListNoUpdates.ForeColor.G + fadingSpeed, lblListNoUpdates.ForeColor.B + fadingSpeed);

        //    if (lblListNoUpdates.ForeColor.R >= this.BackColor.R)
        //    {
        //        tmrFadeLabel.Stop();
        //        lblListNoUpdates.ForeColor = this.BackColor;
        //        lblListNoUpdates.Visible = false;
        //        lblListNoUpdates.ForeColor = System.Drawing.Color.Black;
        //    }
        //}
    }
}
