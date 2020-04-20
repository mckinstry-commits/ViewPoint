namespace McKinstry.ExpenseUploader
{
    partial class Uploader
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.bUpload = new System.Windows.Forms.Button();
            this.tbBatch = new System.Windows.Forms.TextBox();
            this.lblBatch = new System.Windows.Forms.Label();
            this.bUpdateChecks = new System.Windows.Forms.Button();
            this.richTB = new System.Windows.Forms.RichTextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.cbFMS = new System.Windows.Forms.CheckBox();
            this.SuspendLayout();
            // 
            // bUpload
            // 
            this.bUpload.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.bUpload.Location = new System.Drawing.Point(144, 93);
            this.bUpload.Name = "bUpload";
            this.bUpload.Size = new System.Drawing.Size(160, 39);
            this.bUpload.TabIndex = 0;
            this.bUpload.Text = "Process Expenses";
            this.bUpload.UseVisualStyleBackColor = true;
            this.bUpload.Click += new System.EventHandler(this.bUpload_Click);
            // 
            // tbBatch
            // 
            this.tbBatch.Location = new System.Drawing.Point(264, 43);
            this.tbBatch.Name = "tbBatch";
            this.tbBatch.Size = new System.Drawing.Size(251, 20);
            this.tbBatch.TabIndex = 1;
            // 
            // lblBatch
            // 
            this.lblBatch.AutoSize = true;
            this.lblBatch.BackColor = System.Drawing.SystemColors.ActiveCaption;
            this.lblBatch.Cursor = System.Windows.Forms.Cursors.No;
            this.lblBatch.Font = new System.Drawing.Font("Microsoft Sans Serif", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblBatch.Location = new System.Drawing.Point(141, 44);
            this.lblBatch.Name = "lblBatch";
            this.lblBatch.Size = new System.Drawing.Size(93, 16);
            this.lblBatch.TabIndex = 2;
            this.lblBatch.Text = "Batch Number";
            // 
            // bUpdateChecks
            // 
            this.bUpdateChecks.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.bUpdateChecks.Location = new System.Drawing.Point(347, 93);
            this.bUpdateChecks.Name = "bUpdateChecks";
            this.bUpdateChecks.Size = new System.Drawing.Size(168, 39);
            this.bUpdateChecks.TabIndex = 4;
            this.bUpdateChecks.Text = "Update CheckNumbers";
            this.bUpdateChecks.UseVisualStyleBackColor = true;
            this.bUpdateChecks.Click += new System.EventHandler(this.bUpdateChecks_Click);
            // 
            // richTB
            // 
            this.richTB.BackColor = System.Drawing.SystemColors.ActiveCaption;
            this.richTB.BorderStyle = System.Windows.Forms.BorderStyle.None;
            this.richTB.Location = new System.Drawing.Point(12, 167);
            this.richTB.Name = "richTB";
            this.richTB.Size = new System.Drawing.Size(749, 195);
            this.richTB.TabIndex = 5;
            this.richTB.Text = "";
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(13, 148);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(50, 13);
            this.label1.TabIndex = 6;
            this.label1.Text = "Message";
            // 
            // cbFMS
            // 
            this.cbFMS.AutoSize = true;
            this.cbFMS.Location = new System.Drawing.Point(558, 45);
            this.cbFMS.Name = "cbFMS";
            this.cbFMS.Size = new System.Drawing.Size(48, 17);
            this.cbFMS.TabIndex = 7;
            this.cbFMS.Text = "FMS";
            this.cbFMS.UseVisualStyleBackColor = true;
            this.cbFMS.Visible = false;
            // 
            // Uploader
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.SystemColors.ActiveCaption;
            this.ClientSize = new System.Drawing.Size(773, 396);
            this.Controls.Add(this.cbFMS);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.richTB);
            this.Controls.Add(this.bUpdateChecks);
            this.Controls.Add(this.lblBatch);
            this.Controls.Add(this.tbBatch);
            this.Controls.Add(this.bUpload);
            this.Name = "Uploader";
            this.Text = "ExpenseWire To ViewPoint Uploader";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button bUpload;
        private System.Windows.Forms.TextBox tbBatch;
        private System.Windows.Forms.Label lblBatch;
        private System.Windows.Forms.Button bUpdateChecks;
        private System.Windows.Forms.RichTextBox richTB;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.CheckBox cbFMS;
       // private CustomControls.TheBestProgressBarEver uploadProgress;
    }
}

