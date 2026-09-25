using System.ComponentModel.DataAnnotations;
namespace Brokerage.Api.DTOs.Auth;
public class ChangePasswordRequest { [Required, MinLength(8)] public string CurrentPassword { get; init; } = string.Empty; [Required, MinLength(8)] public string NewPassword { get; init; } = string.Empty; }
