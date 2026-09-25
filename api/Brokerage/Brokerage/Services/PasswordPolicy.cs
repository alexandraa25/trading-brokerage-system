namespace Brokerage.Api.Services;
public static class PasswordPolicy
{
    public static bool IsValid(string password) => password.Length >= 10 && password.Any(char.IsUpper) && password.Any(char.IsLower) && password.Any(char.IsDigit) && password.Any(character => !char.IsLetterOrDigit(character));
    public const string Message = "Parola trebuie să aibă minimum 10 caractere și să conțină literă mare, literă mică, cifră și simbol.";
}
