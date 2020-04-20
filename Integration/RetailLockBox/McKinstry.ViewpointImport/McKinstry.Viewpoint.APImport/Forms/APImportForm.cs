using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using McKinstry.ViewpointImport.Common;

namespace McKinstry.Viewpoint.APImport
{
    public partial class APImportForm : Form
    {
        private const string defaultBatchName = "-- Choose Import File --";
        private const int defaultBatchValue = 0;
        private const string defaultBatchDescription = "Choose an import file to upload.";
        private const string errorPrefix = "Error: ";
        private const string missingBatchErrorText = "Missing Import File.";

        List<RLBImportBatch> batches;
        RLBImportBatch batch;

        public APImportForm()
        {
            try
            {
                // Initializes Controls and batch data.  Display default
                // batch data to user. Reports errors to user in MessageBox.
                InitializeComponent();
                PopulateBatchComboBox();
                DisableControl(btnUpload, true);
                ShowBatchInfoToUser();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Application Error");
            }
        }            

        /// <summary>
        /// Binds AdminTaskCollection Collection to ComboBox in UI.  Adds default TaskItem data.
        /// </summary>
        private void PopulateBatchComboBox()
        {
            batches = new List<RLBImportBatch>();
            batches.Insert(0, new RLBImportBatch { FileName = defaultBatchName, RLBImportBatchID = defaultBatchValue });

            using (var ctx = new MckIntegrationEntities(CommonSettings.MckIntegrationConnectionString))
            {
                var items = ctx.RLBImportBatches.Where(b => b.RLBImportBatchStatusCode == "MAN")
                    .ToList<RLBImportBatch>();
                foreach (var item in items)
                {
                    batches.Add(item);
                }
                
            }

            cboBatches.DisplayMember = "FileName";
            cboBatches.ValueMember = "RLBImportBatchID";
            cboBatches.DataSource = batches;
        }

        /// <summary>
        /// Displays Batch data in UI.
        /// </summary>
        private void ShowBatchInfoToUser()
        {
            if ((batches.Count > 0) && (cboBatches.SelectedIndex >= 0))
            {
                batch = batches
                    .Where(b => b.RLBImportBatchID.ToString() == cboBatches.SelectedValue.ToString())
                    .FirstOrDefault<RLBImportBatch>();
                lblFileName.Text = batch.FileName == defaultBatchName ? "" : batch.FileName;
                lblProcessDate.Text = batch.Modified.HasValue ? batch.Modified.Value.ToString("g") : "";
                lblFileSize.Text = batch.Length > 0 ? String.Concat((batch.Length/1024).ToString("N0"), " KB") : "";
                lblArchive.Text = batch.ArchiveFolderName;
            }
        }

        /// <summary>
        /// Sets Enabled property of input Control based on disable parameter.  Disables 
        /// Control if disable parameter is true, enables Control if disable parameter is false.
        /// </summary>
        /// <param name="control">Control to check</param>
        /// <param name="disable">Disable control (true/false)</param>
        private void DisableControl(Control control, bool disable)
        {
            if ((disable) && (control.Enabled))
            {
                control.Enabled = false;
            }
            else
            {
                if (!control.Enabled)
                {
                    control.Enabled = true;
                }
            }
        }

        /// <summary>
        /// Batch ComboBox event handler. Shows batch data to users based on user selection. 
        /// Reports errors to user in MessageBox.
        /// </summary>
        private void cboBatches_SelectedIndexChanged(object sender, EventArgs e)
        {
            try
            {
                if (cboBatches.SelectedIndex >= 0)
                {
                    ShowBatchInfoToUser();
                    if (cboBatches.SelectedValue.ToString().Equals(defaultBatchValue.ToString()))
                    {
                        DisableControl(btnUpload, true);
                    }
                    else
                    {
                        DisableControl(btnUpload, false);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Application Error");
            }
        }

        /// <summary>
        /// Upload button click event. Perform AP upload.
        /// </summary>
        private void btnUpload_Click(object sender, EventArgs e)
        {
            try
            {
                if (cboBatches.SelectedIndex > 0)
                {
                    lblProgress.Text = string.Format("Processing:  {0} .....", batch != null ? batch.FileName : "");
                    DisableControl(btnUpload, true);
                    DisableControl(cboBatches, true);
                    DisableControl(btnClose, true);
                    APImport import = new APImport(cboBatches.SelectedValue.ToString());
                    import.RunImport();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Application Error");
                lblProgress.Text = string.Format("Error: {0}.", ex.Message);
            }
            finally
            {
                DisableControl(btnUpload, false);
                DisableControl(cboBatches, false);
                DisableControl(btnClose, false);
                PopulateBatchComboBox();
                lblProgress.Text = string.Empty;
            }
        }

        /// <summary>
        /// Close button click event. Close form.
        /// </summary>
        private void btnClose_Click(object sender, EventArgs e)
        {
            try
            {
                this.Close();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, "Application Error");
            }
        }

        /// <summary>
        /// Form load event.  Disable and clear controls.
        /// </summary>
        private void APImportForm_Load(object sender, EventArgs e)
        {
            DisableControl(btnUpload, true);
            lblProgress.Text = string.Empty;
        }
    }
}
