using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CareerCloud.Pocos
{
    [Table("Company_Job_Educations")]
    public class CompanyJobEducationPoco : IPoco
    {
        [Column("Id")]
        [Key]
        public Guid Id { get; set; }
        [Column("Job")]
        public Guid Job { get; set; }
        [Column("Major")]
        public string? Major { get; set; }
        [Column("Importance")]
        public Int16 Importance { get; set; }
        [Column("Time_Stamp")]
        [NotMapped]
        public byte[]? TimeStamp { get; set; }

        //Virtual link with affiliate table
        [ForeignKey("Job")]
        public virtual CompanyJobPoco? CompanyJob { get; set; }
    }
}
