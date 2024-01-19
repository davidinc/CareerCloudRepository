using CareerCloud.DataAccessLayer;
using CareerCloud.Pocos;

namespace CareerCloud.BusinessLogicLayer
{
    public class SystemLanguageCodeLogic 
    {
        protected IDataRepository<SystemLanguageCodePoco> _repository;
        public SystemLanguageCodeLogic(IDataRepository<SystemLanguageCodePoco> repository) 
        { 
            _repository = repository;
        }

        protected virtual void Verify(SystemLanguageCodePoco[] pocos)
        {
            foreach (var poco in pocos)
            {

                List<ValidationException> errors = new List<ValidationException>();

                // Defining Exceptional validation for ErrorCode 1000/1001/1002
                if (string.IsNullOrEmpty(poco.LanguageID))
                {
                    errors.Add(new ValidationException(1000, "Cannot be empty"));
                }

                if (string.IsNullOrEmpty(poco.Name))

                {
                    errors.Add(new ValidationException(1001, "Cannot be empty"));
                }
                if (string.IsNullOrEmpty(poco.NativeName))

                {
                    errors.Add(new ValidationException(1002, "Cannot be empty"));
                }


                if (errors.Count > 0)
                {
                    throw new AggregateException(errors);
                }
            }
        }

        public virtual SystemLanguageCodePoco GetByLanguageId(string languageId)
        {
            return _repository.GetSingle(c => c.LanguageID == languageId);
        }

        public virtual List<SystemLanguageCodePoco> GetAll()
        {
            return _repository.GetAll().ToList();
        }


        public SystemLanguageCodePoco Get(string langId)
        {
            return _repository.GetSingle(c => c.LanguageID == langId);
        }

        public virtual void Add(SystemLanguageCodePoco[] pocos)
        {

            Verify(pocos);
            _repository.Add(pocos);
        }

        public virtual void Update(SystemLanguageCodePoco[] pocos)
        {
            Verify(pocos);
            _repository.Update(pocos);
        }

        public void Delete(SystemLanguageCodePoco[] pocos)
        {
            _repository.Remove(pocos);
        }
    }


}

