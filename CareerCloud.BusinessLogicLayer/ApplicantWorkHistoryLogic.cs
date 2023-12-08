using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class ApplicantWorkHistoryLogic : BaseLogic<ApplicantWorkHistoryPoco>
    {
        public ApplicantWorkHistoryLogic(IDataRepository<ApplicantWorkHistoryPoco> repository) : base(repository) 
        { }

        protected override void Verify(ApplicantWorkHistoryPoco[] pocos)
        {

            foreach (var poco in pocos)
            {
                List<ValidationException> errors = new List<ValidationException>();

                // Defining Exceptional validation for ErrorCode 105
                if (poco.CompanyName.Length <= 2)
                {
                    errors.Add(new ValidationException(105, "Must be greater then 2 characters"));
                }

                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }

        }

        public override void Add(ApplicantWorkHistoryPoco[] pocos)
        {
            Verify(pocos);
            base.Add(pocos);
        }

        public override void Update(ApplicantWorkHistoryPoco[] pocos)
        {
            Verify(pocos);
            base.Update(pocos);
        }

    }
}
