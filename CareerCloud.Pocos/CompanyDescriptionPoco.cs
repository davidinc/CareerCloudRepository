using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;


namespace CareerCloud.Pocos
{
    [Table("Company_Descriptions")]
    public class CompanyDescriptionPoco : IPoco
    {
        [Column("Id")]
        [Key]
        public Guid Id { get; set; }
        [Column("Company")]
        public Guid Company { get; set; }
        [Column("LanguageId")]
        public string? LanguageId { get; set; }
        [Column("Company_Name")]
        public string? CompanyName { get; set; }
        [Column("Company_Description")]
        public string? CompanyDescription { get; set; }
        [Column("Time_Stamp")]
        [NotMapped]
        public byte[]? TimeStamp { get; set; }


        //Virtual link with affiliate table
        [ForeignKey("Company")]
        public virtual CompanyProfilePoco? CompanyProfile { get; set; }
        public virtual SystemLanguageCodePoco? SystemLanguageCode { get; set; }
    }
}
