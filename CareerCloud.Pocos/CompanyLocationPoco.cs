using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CareerCloud.Pocos
{
    [Table("Company_Locations")]
    public class CompanyLocationPoco:IPoco
    {
        [Column("Id")]
        [Key]
        public Guid Id { get; set; }
        [Column("Company")]
        public Guid Company { get; set; }
        [Column("Country_Code")]
        public string? CountryCode { get; set; }
        [Column("State_Province_Code")]
        public string? Province { get; set; }
        [Column("Street_Address")]
        public string? Street { get; set; }
        [Column("City_Town")]
        public string? City { get; set; }
        [Column("Zip_Postal_Code")]
        public string? PostalCode { get; set; }
        [Column("Time_Stamp")]
        [NotMapped]
        public byte[]? TimeStamp { get; set; }

        //Virtual link with affiliate table
        [ForeignKey(nameof(Company))]
        public virtual CompanyProfilePoco? CompanyProfile { get; set; }
        public virtual SystemCountryCodePoco? SystemCountryCode { get; set; }
      
    }
}
