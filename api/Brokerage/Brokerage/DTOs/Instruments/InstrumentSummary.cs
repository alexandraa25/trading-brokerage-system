namespace Brokerage.Api.DTOs.Instruments;

public record InstrumentSummary(
    long InstrumentId,
    string Symbol,
    string InstrumentName,
    string InstrumentType,
    string Currency,
    string MarketName,
    string IssuerName,
    decimal? MarketPrice,
    DateTime? QuoteDate,
    string? QuoteSource);
