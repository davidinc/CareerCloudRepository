using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;


namespace CareerCloud.Pocos
{
    [Table("System_Country_Codes")]
    public class SystemCountryCodePoco
    {
        [Column("Code")]
        [Key]
        public string? Code { get; set; }
        [Column("Name")]
        public string? Name { get; set; }

        //Virtual link with affiliate table
        public virtual ICollection<ApplicantProfilePoco>? ApplicantProfile { get; set; }
        public virtual ICollection<ApplicantWorkHistoryPoco>? ApplicantWorkHistory { get; set; }
        public virtual ICollection<CompanyLocationPoco>? CompanyLocations { get; set; }

    }
}
