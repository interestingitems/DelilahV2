unit delilah.strategy.gdax.tiers;

{$mode delphi}

interface

uses
  Classes, SysUtils, delilah.strategy.channels, delilah.types,
  delilah.strategy.gdax, fgl, delilah.strategy;

type

  (*
    enum showing all available order positions taken at a particular tier
  *)
  TPositionSize = (
    psSmall,
    psMid,
    psLarge,
    psGTFO
  );

  { ITierStrategyGDAX }
  (*
    strategy which sets various channels above and below each other (tiered)
    in order to open and close different sized positions
  *)
  ITierStrategyGDAX = interface(IStrategyGDAX)
    ['{C9AA33EF-DB73-4790-BD48-5AB5E27A4A81}']
    function GetAvoidChop: Boolean;
    //property methods
    function GetChannel: IChannelStrategy;
    function GetGTFOPerc: Single;
    function GetIgnoreProfit: Single;
    function GetLargePerc: Single;
    function GetLargeSellPerc: Single;
    function GetLimitFee: Single;
    function GetMarketFee: Single;
    function GetMidPerc: Single;
    function GetMidSellPerc: Single;
    function GetMinProfit: Single;
    function GetMinReduction: Single;
    function GetOnlyLower: Boolean;
    function GetOnlyProfit: Boolean;
    function GetSmallPerc: Single;
    function GetSmallSellPerc: Single;
    function GetUseMarketBuy: Boolean;
    function GetUseMarketSell: Boolean;
    procedure SetAvoidChop(Const AValue: Boolean);
    procedure SetGTFOPerc(Const AValue: Single);
    procedure SetIgnoreProfit(Const AValue: Single);
    procedure SetLargePerc(Const AValue: Single);
    procedure SetLargeSellPerc(Const AValue: Single);
    procedure SetLimitFee(Const AValue: Single);
    procedure SetMarketFee(Const AValue: Single);
    procedure SetMarketSell(Const AValue: Boolean);
    procedure SetMidPerc(Const AValue: Single);
    procedure SetMidSellPerc(Const AValue: Single);
    procedure SetMinProfit(Const AValue: Single);
    procedure SetMinReduction(Const AValue: Single);
    procedure SetOnlyLower(Const AValue: Boolean);
    procedure SetOnlyProfit(Const AValue: Boolean);
    procedure SetSmallPerc(Const AValue: Single);
    procedure SetSmallSellPerc(Const AValue: Single);
    procedure SetUseMarketBuy(Const AValue: Boolean);

    //properties
    (*
      specific details about all channels used can be accessed from this
      property, and changed if required
    *)
    property ChannelStrategy : IChannelStrategy read GetChannel;
    (*
      when true, sell orders can only be placed if it would result in profit
    *)
    property OnlyProfit : Boolean read GetOnlyProfit write SetOnlyProfit;
    (*
      when inventory makes up a certain "threshold" percentage compared
      to funds available, a sell is allowed. If this setting is not desired
      set to 0 or something greater than 1.0 (100%)
    *)
    property IgnoreOnlyProfitThreshold : Single read GetIgnoreProfit write SetIgnoreProfit;
    (*
      minimum percentage to sell inventory for, only works with OnlyProfit true
    *)
    property MinProfit : Single read GetMinProfit write SetMinProfit;
    (*
      when true, buy orders can only be placed if it would lower AAC
    *)
    property OnlyLowerAAC : Boolean read GetOnlyLower write SetOnlyLower;
    (*
      minimum percentage to reduce AAC, only works when OnlyLowerAAC is True
    *)
    property MinReduction : Single read GetMinReduction write SetMinReduction;
    (*
      when true, market orders are made for buys instead of limit orders ensuring
      a quick entry price, but most likely incurring fees
    *)
    property UseMarketBuy : Boolean read GetUseMarketBuy write SetUseMarketBuy;
    (*
      when true, market orders are made for sells instead of limit orders ensuring
      a quick exit price, but most likely incurring fees
    *)
    property UseMarketSell : Boolean read GetUseMarketSell write SetMarketSell;
    (*
      using a combination of order fee and min profit, will look at the anchor
      and deviations to try and avoid purchasing inventory in choppy conditions.
      this should avoid loading up on bags during uncertain times
    *)
    property AvoidChop : Boolean read GetAvoidChop write SetAvoidChop;
    (*
      the market fee associated with market orders. this setting is used
      in conjunction with OnlyProfit to determine if a sell can be made
    *)
    property MarketFee : Single read GetMarketFee write SetMarketFee;
    (*
      the fee associated with limit fee (works like marketfee)
    *)
    property LimitFee : Single read GetLimitFee write SetLimitFee;
    (*
      percentage of funds/inventory to use when a small tier position is detected buying
    *)
    property SmallTierPerc : Single read GetSmallPerc write SetSmallPerc;
    (*
      percentage of funds/inventory to use when a medium tier position is detected buying
    *)
    property MidTierPerc : Single read GetMidPerc write SetMidPerc;
    (*
      percentage of funds/inventory to use when a large tier position is detected buying
    *)
    property LargeTierPerc : Single read GetLargePerc write SetLargePerc;
    (*
      percentage of funds/inventory to use when a small tier position is detected selling
    *)
    property SmallTierSellPerc : Single read GetSmallSellPerc write SetSmallSellPerc;
    (*
      percentage of funds/inventory to use when a medium tier position is detected selling
    *)
    property MidTierSellPerc : Single read GetMidSellPerc write SetMidSellPerc;
    (*
      percentage of funds/inventory to use when a large tier position is detected selling
    *)
    property LargeTierSellPerc : Single read GetLargeSellPerc write SetLargeSellPerc;
    (*
      when GTFO signal is reached, determines the percentage of inventory to sell
    *)
    property GTFOPerc : Single read GetGTFOPerc write SetGTFOPerc;
  end;

  { TTierStrategyGDAXImpl }
  (*
    base implementation of a GDAX tiered stragegy
  *)
  TTierStrategyGDAXImpl = class(TStrategyGDAXImpl,ITierStrategyGDAX)
  strict private
    FChannel: IChannelStrategy;
    FOnlyLower,
    FOnlyProfit,
    FUseMarketBuy,
    FUseMarketSell: Boolean;
    FSmallPerc,
    FMidPerc,
    FMarketFee,
    FLimitFee,
    FLargePerc,
    FSmallSellPerc,
    FMidSellPerc,
    FLargeSellPerc,
    FMinProfit,
    FMinReduction,
    FGTFOPerc,
    FIgnoreProfitPerc: Single;
    FDontBuy,
    FSellItAllNow,
    FLargeBuy,
    FSmallBuy,
    FLargeSell,
    FMidSell,
    FSmallSell,
    FAvoidChop: Boolean;
    FIDS: TFPGList<String>;
    function GetChannel: IChannelStrategy;
    function GetLargePerc: Single;
    function GetLargeSellPerc: Single;
    function GetMarketFee: Single;
    function GetLimitFee: Single;
    function GetMidPerc: Single;
    function GetMidSellPerc: Single;
    function GetMinProfit: Single;
    function GetMinReduction: Single;
    function GetOnlyLower: Boolean;
    function GetOnlyProfit: Boolean;
    function GetSmallPerc: Single;
    function GetSmallSellPerc: Single;
    function GetUseMarketBuy: Boolean;
    function GetUseMarketSell: Boolean;
    function GetGTFOPerc: Single;
    function GetIgnoreProfit: Single;
    procedure SetLargePerc(Const AValue: Single);
    procedure SetLargeSellPerc(Const AValue: Single);
    procedure SetMarketFee(Const AValue: Single);
    procedure SetLimitFee(Const AValue: Single);
    procedure SetMarketSell(Const AValue: Boolean);
    procedure SetMidPerc(Const AValue: Single);
    procedure SetMidSellPerc(Const AValue: Single);
    procedure SetMinProfit(Const AValue: Single);
    procedure SetMinReduction(Const AValue: Single);
    procedure SetOnlyLower(Const AValue: Boolean);
    procedure SetOnlyProfit(Const AValue: Boolean);
    procedure SetSmallPerc(Const AValue: Single);
    procedure SetSmallSellPerc(Const AValue: Single);
    procedure SetUseMarketBuy(Const AValue: Boolean);
    procedure SetGTFOPerc(Const AValue: Single);
    procedure SetIgnoreProfit(Const AValue: Single);
    procedure InitChannel;
    procedure GTFOUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure GTFOLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeBuyUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeBuyLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallBuyUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallBuyLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallSellUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallSellLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeSellUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeSellLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    function GetAvoidChop: Boolean;
    procedure SetAvoidChop(const AValue: Boolean);
  strict protected
    const
      GTFO = 'gtfo';
      LARGE_BUY = 'large-buy';
      SMALL_BUY = 'small-buy';
      SMALL_SELL = 'small-sell';
      LARGE_SELL = 'large-sell';
  strict protected
    function DoFeed(const ATicker: ITicker; const AManager: IOrderManager;
      const AFunds, AInventory, AAAC: Extended; out Error: String): Boolean;override;
    (*
      returns true if we should take a particular position
    *)
    function GetPosition(Const AInventory:Extended;Out Size:TPositionSize;Out Percentage:Single;Out Sell:Boolean):Boolean;
    (*
      after a call is made to GetPosition, call this method to report that
      we were successful placing to the order manager
    *)
    procedure PositionSuccess;
    (*
      clears managed positions by cancelling those not completed
    *)
    procedure ClearOldPositions(Const AManager:IOrderManager);
    function ChoppyWaters : Boolean;
  public

    property ChannelStrategy : IChannelStrategy read GetChannel;
    property OnlyProfit : Boolean read GetOnlyProfit write SetOnlyProfit;
    property IgnoreOnlyProfitThreshold : Single read GetIgnoreProfit write SetIgnoreProfit;
    property MinProfit : Single read GetMinProfit write SetMinProfit;
    property OnlyLowerAAC : Boolean read GetOnlyLower write SetOnlyLower;
    property MinReduction : Single read GetMinReduction write SetMinReduction;
    property UseMarketBuy : Boolean read GetUseMarketBuy write SetUseMarketBuy;
    property UseMarketSell : Boolean read GetUseMarketSell write SetMarketSell;
    property AvoidChop : Boolean read GetAvoidChop write SetAvoidChop;
    property MarketFee : Single read GetMarketFee write SetMarketFee;
    property LimitFee : Single read GetLimitFee write SetLimitFee;
    property SmallTierPer : Single read GetSmallPerc write SetSmallPerc;
    property MidTierPerc : Single read GetMidPerc write SetMidPerc;
    property LargeTierPerc : Single read GetLargePerc write SetLargePerc;
    property SmallTierSellPerc : Single read GetSmallSellPerc write SetSmallSellPerc;
    property MidTierSellPerc : Single read GetMidSellPerc write SetMidSellPerc;
    property LargeTierSellPerc : Single read GetLargeSellPerc write SetLargeSellPerc;
    property GTFOPerc : Single read GetGTFOPerc write SetGTFOPerc;
    constructor Create(const AOnInfo, AOnError, AOnWarn: TStrategyLogEvent);override;
    destructor Destroy; override;
  end;

implementation
uses
  math,
  gdax.api.consts,
  gdax.api.types,
  gdax.api.orders,
  delilah.ticker.gdax,
  delilah.order.gdax;

{ TTierStrategyGDAXImpl }

function TTierStrategyGDAXImpl.GetChannel: IChannelStrategy;
begin
  Result:=FChannel;
end;

function TTierStrategyGDAXImpl.GetLargePerc: Single;
begin
  Result:=FLargePerc;
end;

function TTierStrategyGDAXImpl.GetLargeSellPerc: Single;
begin
  Result:=FLargeSellPerc;
end;

function TTierStrategyGDAXImpl.GetMarketFee: Single;
begin
  Result:=FMarketFee;
end;

function TTierStrategyGDAXImpl.GetLimitFee: Single;
begin
  Result:=FLimitFee;
end;

function TTierStrategyGDAXImpl.GetMidPerc: Single;
begin
  Result:=FMidPerc;
end;

function TTierStrategyGDAXImpl.GetMidSellPerc: Single;
begin
  Result:=FMidSellPerc;
end;

function TTierStrategyGDAXImpl.GetMinProfit: Single;
begin
  Result:=FMinProfit;
end;

function TTierStrategyGDAXImpl.GetMinReduction: Single;
begin
  Result:=FMinReduction;
end;

function TTierStrategyGDAXImpl.GetOnlyLower: Boolean;
begin
  Result:=FOnlyLower;
end;

function TTierStrategyGDAXImpl.GetOnlyProfit: Boolean;
begin
  Result:=FOnlyProfit;
end;

function TTierStrategyGDAXImpl.GetSmallPerc: Single;
begin
  Result:=FSmallPerc;
end;

function TTierStrategyGDAXImpl.GetSmallSellPerc: Single;
begin
  Result:=FSmallSellPerc;
end;

function TTierStrategyGDAXImpl.GetUseMarketBuy: Boolean;
begin
  Result:=FUseMarketBuy;
end;

function TTierStrategyGDAXImpl.GetUseMarketSell: Boolean;
begin
  Result:=FUseMarketSell;
end;

function TTierStrategyGDAXImpl.GetGTFOPerc: Single;
begin
  Result:=FGTFOPerc;
end;

function TTierStrategyGDAXImpl.GetIgnoreProfit: Single;
begin
  Result:=FIgnoreProfitPerc;
end;

procedure TTierStrategyGDAXImpl.SetLargePerc(const AValue: Single);
begin
  if AValue<0 then
    FLargePerc:=0
  else
    FLargePerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetLargeSellPerc(const AValue: Single);
begin
  FLargeSellPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMarketFee(const AValue: Single);
begin
  FMarketFee:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetLimitFee(const AValue: Single);
begin
  FLimitFee:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMarketSell(const AValue: Boolean);
begin
  FUseMarketSell:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMidPerc(const AValue: Single);
begin
  if AValue<0 then
    FMidPerc:=AValue
  else
    FMidPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMidSellPerc(const AValue: Single);
begin
  FMidSellPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMinProfit(const AValue: Single);
begin
  FMinProfit:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMinReduction(const AValue: Single);
begin
  FMinReduction:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetOnlyLower(const AValue: Boolean);
begin
  FOnlyLower:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetOnlyProfit(const AValue: Boolean);
begin
  FOnlyProfit:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetSmallPerc(const AValue: Single);
begin
  if AValue<0 then
    FSmallPerc:=AValue
  else
    FSmallPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetSmallSellPerc(const AValue: Single);
begin
  FSmallSellPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetUseMarketBuy(const AValue: Boolean);
begin
  FUseMarketBuy:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetGTFOPerc(const AValue: Single);
begin
  FGTFOPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetIgnoreProfit(const AValue: Single);
begin
  FIgnoreProfitPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.InitChannel;
var
  LGTFO,
  LLargeBuy,
  LSmallBuy,
  LSmallSell,
  LLargeSell:IChannel;
begin
  //todo - these numbers are "magic" right now, should break them out
  //into a properties maybe

  LGTFO:=FChannel.Add(GTFO,-3.5,-4)[GTFO];
  LGTFO.OnLower:=GTFOLow;
  LGTFO.OnUpper:=GTFOUp;

  LLargeBuy:=FChannel.Add(LARGE_BUY,-2,-3)[LARGE_BUY];
  LLargeBuy.OnLower:=LargeBuyUp;
  LLargeBuy.OnUpper:=LargeBuyLow;

  LSmallBuy:=FChannel.Add(SMALL_BUY,0,-1)[SMALL_BUY];
  LSmallBuy.OnUpper:=SmallBuyUp;
  LSmallBuy.OnLower:=SmallBuyLow;

  LSmallSell:=FChannel.Add(SMALL_SELL,1,0)[SMALL_SELL];
  LSmallSell.OnUpper:=SmallSellUp;
  LSmallSell.OnLower:=SmallSellLow;

  LLargeSell:=FChannel.Add(LARGE_SELL,3,2)[LARGE_SELL];
  LLargeSell.OnUpper:=LargeSellUp;
  LLargeSell.OnLower:=LargeSellLow;
end;

procedure TTierStrategyGDAXImpl.GTFOUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('GTFOUp::direction is ' + IntToStr(Ord(ADirection)));
  //entering or exiting this channel from the upper bounds puts us in a
  //"watch" mode for GTFO by toggling the "dont buy" flag
  case ADirection of
   cdEnter: FDontBuy:=True;
   cdExit: FDontBuy:=False;
 end;
end;

procedure TTierStrategyGDAXImpl.GTFOLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('GTFOLow::direction is ' + IntToStr(Ord(ADirection)));
  //we need to gtfo...
  case ADirection of
    cdExit: FSellItAllNow:=True;
    cdEnter: FSellItAllNow:=False;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeBuyUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeBuyUp::direction is ' + IntToStr(Ord(ADirection)));
  //if we break the upper bounds, we're probably going higher
  case ADirection of
    cdExit: FLargeBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeBuyLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeBuyLow::direction is ' + IntToStr(Ord(ADirection)));
  //entering from the lower bound of this channel means it's a good oppurtunity
  //to buy in, while exiting, means hold off
  case ADirection of
    cdEnter: FLargeBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallBuyUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallBuyUp::direction is ' + IntToStr(Ord(ADirection)));
  //if we break the upper bounds, we're probably going higher
  case ADirection of
    cdExit: FSmallBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallBuyLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallBuyLow::direction is ' + IntToStr(Ord(ADirection)));
  //entering from the lower bound of this channel means it's a good oppurtunity
  //to buy in, while exiting, means hold off
  case ADirection of
    cdEnter: FSmallBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallSellUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallSellUp::direction is ' + IntToStr(Ord(ADirection)));
  //entering/exiting both trigger a sell
  case ADirection of
    cdEnter,cdExit: FSmallSell:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallSellLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallSellLow::direction is ' + IntToStr(Ord(ADirection)));
  //entering/exiting both trigger a sell
  case ADirection of
    cdEnter,cdExit: FSmallSell:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeSellUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeSellUp::direction is ' + IntToStr(Ord(ADirection)));
  //large sell exiting puts us into to large sell mode, while
  //entering puts us back to mid sell
  case ADirection of
    cdExit: FLargeSell:=True;
    cdEnter: FMidSell:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeSellLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeSellLow::direction is ' + IntToStr(Ord(ADirection)));
  //the lower channel controls mid-range sell oppurtunities
  case ADirection of
    cdEnter,cdExit: FMidSell:=True;
  end;
end;

function TTierStrategyGDAXImpl.DoFeed(const ATicker: ITicker;
  const AManager: IOrderManager; const AFunds, AInventory, AAAC: Extended; out
  Error: String): Boolean;
var
  I:Integer;
  LID:String;
  LTicker:ITickerGDAX;
  LSize:TPositionSize;
  LOrderSize,
  LMin:Extended;
  LPerc,
  LOrderSellTot,
  LOrderBuyTot:Single;
  LSell,
  LAllowLoss:Boolean;
  LGDAXOrder:IGDAXOrder;
  LDetails:IOrderDetails;
  LChannel:IChannel;
begin
  Result:=inherited DoFeed(ATicker, AManager, AFunds, AInventory, AAAC, Error);
  if not Result then
    Exit;
  Result:=False;
  try
    //feed the channel
    if not FChannel.Feed(ATicker,AManager,AFunds,AInventory,AAAC,Error) then
      Exit;

    if not FChannel.IsReady then
    begin
      LogInfo(
        Format(
          'window is not ready [size]:%d [collected]:%d',
          [
            FChannel.WindowSizeInMilli,
            FChannel.CollectedSizeInMilli
          ]
        )
      );
      Exit(True);
    end;

    //log the channels' state
    LogInfo('DoFeed::[StdDev]:' + FloatToStr(FChannel.StdDev));
    for I:=0 to Pred(FChannel.Count) do
    begin
      LChannel:=FChannel.ByIndex[I];
      LogInfo('DoFeed::channel ' + LChannel.Name + ' ' +
        '[anchor]-' + FloatToStr(LChannel.AnchorPrice) + ' ' +
        '[lower]-' + FloatToStr(LChannel.Lower) + ' ' +
        '[upper]-' + FloatToStr(LChannel.Upper)
      );
      LChannel:=nil;
    end;

    //cast to gdax ticker
    LTicker:=ATicker as ITickerGDAX;
    LMin:=RoundTo(LTicker.Ticker.Product.BaseMinSize,-8);

    //initialize the order
    LGDAXOrder:=TGDAXOrderImpl.Create;
    LGDAXOrder.Product:=LTicker.Ticker.Product;

    //get whether or not we should make a position
    if GetPosition(AInventory,LSize,LPerc,LSell) then
    begin
      //this will remove any old limit orders outstanding
      ClearOldPositions(AManager);

      //see if we need to place a sell
      if LSell then
      begin
        LogInfo('DoFeed::sell logic reached');

        //if a gtfo siganl occurred, but no percentage was specified
        //return here so the minimum logic won't be reached
        if (LSize = psGTFO) and (LPerc <= 0) then
        begin
          LogInfo('DoFeed::GTFO occurred, but gtfo percentage is 0, exiting');
          Exit(True);
        end;

        //set the order size based off the percentage returned to us
        LOrderSize:=RoundTo(Abs(AInventory * LPerc),-8);

        //now make sure we respect the quote increment (ie. can only sell
        //in increments of quote increment, so min order size of 1.0 quote inc
        //of 1.0, and our calc returned 3.5, we would have to sell 3)
        if LOrderSize > 0 then
        begin
          //this code is for a suspect bug in cb quote inc for small
          //coins (where min unit is whole number)
          if RoundTo(LGDAXOrder.Product.BaseMinSize,-1) >= 1 then
            LOrderSize:=Trunc(LOrderSize)
          else
            LOrderSize:=Trunc(LOrderSize / LGDAXOrder.Product.QuoteIncrement) * LGDAXOrder.Product.QuoteIncrement;
        end;

        //last catch to see if our calculation would be less than min
        //but we have at least min size inventory remaining to sell
        if (RoundTo(LOrderSize,-8) <= LMin) and (RoundTo(AInventory,-8) >= LMin) then
        begin
          LogInfo('DoFeed::SellMode::order is small, but we have at least min setting size of order to min');
          LOrderSize:=LMin;
        end;

        //check to see if we have enough inventory to perform a sell
        if (RoundTo(LOrderSize,-8) < RoundTo(LMin,-8)) or (RoundTo(LOrderSize,-8) > RoundTo(AInventory,-8)) then
        begin
          LogInfo(Format('DoFeed::SellMode::%s is lower than min size or no inventory',[FloatToStr(LOrderSize)]));
          LogInfo('DoFeed::SellMode::clearing signals');

          //although this is not a "success" we have no inventory, and should still should clear the signals
          //to allow for buys to be acted on since sells are prioritized
          PositionSuccess;
          Exit(True);
        end;

        //based on the threshold percentage and how much inventory to funds
        //we currently have, we may allow selling at a loss when only profit is on
        //or if we need to gtfo
        LAllowLoss:=
          (
            FOnlyProfit
            and (FIgnoreProfitPerc > 0)
            and ((AFunds + (AInventory * AAAC)) > 0)
            and (((AInventory * AAAC) / (AFunds + (AInventory * AAAC))) >= FIgnoreProfitPerc)
          )
          or (
            LSize = psGTFO
          );

        if LAllowLoss then
          LogInfo('DoFeed::SellMode::OnlyProfit is on and conditions were right to allow selling at a loss');

        //if we are in only profit mode, we need to some validation before
        //placing an order
        if FOnlyProfit and (not LAllowLoss) then
        begin
          //figure out the total amount depending on limit/market
          if FUseMarketSell then
          begin
            //figure the amount of currency we would receive minus the fees
            LOrderSellTot:=(LOrderSize * LTicker.Ticker.Ask) - (FMarketFee * LOrderSize * LTicker.Ticker.Ask);
            LGDAXOrder.OrderType:=otMarket;
            LogInfo('DoFeed::SellMode::using market sell, with OnlyProfit, total sell amount would be ' + FloatToStr(LOrderSellTot));
          end
          else
          begin
            LOrderSellTot:=(LOrderSize * LTicker.Ticker.Ask) - (FLimitFee * LOrderSize * LTicker.Ticker.Ask);
            LGDAXOrder.OrderType:=otLimit;
            LGDAXOrder.Price:=LTicker.Ticker.Ask;
            LogInfo('DoFeed::SellMode::using limit sell, with OnlyProfit, total sell amount would be ' + FloatToStr(LOrderSellTot));
          end;

          //if the cost to sell is less-than aquisition of size, we would be
          //losing money, and that is not allowed in this case
          if LOrderSellTot < (AAAC * LOrderSize) then
          begin
            LogInfo('DoFeed::SellMode::sell would result in loss, and OnlyProfit is on, exiting');
            Exit(True)
          end;

          //if we have a minimum profit, see if we've met the criteria
          if (FMinProfit > 0)
            and ((LOrderSellTot - (AAAC * LOrderSize)) / (AAAC * LOrderSize) < FMinProfit) then
          begin
            LogInfo('DoFeed::SellMode::a minimum profit is set and the current ask price is less, exiting');
            Exit(True);
          end;
        end
        else
        begin
          if FUseMarketSell then
            LGDAXOrder.OrderType:=otMarket
          else
          begin
            LGDAXOrder.OrderType:=otLimit;
            LGDAXOrder.Price:=LTicker.Ticker.Ask;
          end;
        end;

        //set the order side to sell
        LGDAXOrder.Side:=osSell;
        LGDAXOrder.Size:=LOrderSize;
      end
      //otherwise we are seeing if we can open a buy position
      else
      begin
        LogInfo('DoFeed::buy logic');
        //see if we have enough funds to cover either a limit or market
        LOrderBuyTot:=Abs(RoundTo(AFunds * LPerc,-8));

        if LOrderBuyTot > AFunds then
        begin
          LogInfo(Format('DoFeed::BuyMode::would need %f funds, but only %f',[LOrderBuyTot,AFunds]));
          Exit(True);
        end;

        //set the order size based on the amount of funds we have
        //and how many units of min this will purchase
        LOrderSize:=Trunc(LOrderBuyTot / LTicker.Ticker.Bid / LMin) * LMin;

        //our percentage would be too small, but we have at least min, so set
        //to min in order to make a purchase
        if (LOrderSize < LMin)
          and (RoundTo(AFunds / LTicker.Ticker.Bid,-8) >= LMin)
        then
          LOrderSize:=LMin;

        //check to see the order size isn't too small
        if LOrderSize < LMin then
        begin
          LogInfo(Format('DoFeed::BuyMode::%s is lower than min size',[FloatToStr(LOrderSize)]));
          LogInfo('DoFeed::BuyMode::clearing signals');
          PositionSuccess;
          Exit(True);
        end;

        //before doing any other calcs/comparisons, see if we are in
        //choppy conditions, if so get out
        if FAvoidChop and ChoppyWaters then
        begin
          LogInfo('DoFeed::BuyMode::choppy waters cap''n, gon hold off from buyin.');
          PositionSuccess;
          Exit(True);
        end;

        //simple check to see if bid is lower than aac when requested
        if FOnlyLower and (RoundTo(AInventory,-8) >= LMin) then
        begin
          //initially set this variable to what the AAC would be if a limit
          //order was successful since this will be the most common type of order
          LOrderBuyTot:=((LOrderSize * ((1 + FLimitFee) * LTicker.Ticker.Bid) + (AAAC * AInventory)) / (LOrderSize + AInventory));

          //check to see if the limit order would result in a higher AAC
          if not FUseMarketBuy and (LOrderBuyTot > AAAC) then
          begin
            LogInfo(Format('DoFeed::BuyMode::[new aac]:%f is not lower than [aac]:%f',[LOrderBuyTot,AAAC]));
            Exit(True);
          end
          //account for what the new aac "would" be assuming we get the order
          //placed at this price, with the specified fee. this can't account
          //for slippage, or if the price moves by the time the order is actually
          //made, but it's the best that can be done
          else if FUseMarketBuy and ((AInventory > 0) and (AAAC > 0)) then
          begin
            //use this variable to hold what aac would be if successfull accounting for fee
            LOrderBuyTot:=((LOrderSize * ((1 + FMarketFee) * LTicker.Ticker.Bid) + (AAAC * AInventory)) / (LOrderSize + AInventory));

            //check to see if the estimated aac is not greater than the current aac
            if LOrderBuyTot > AAAC then
            begin
              LogInfo(Format('DoFeed::BuyMode::market order shows higher [aac]:%f than [current aac]:%f',[LOrderBuyTot,AAAC]));
              Exit(True);
            end;
          end;

          //make sure we are reducing by the minimum amount, using the calculated
          //new aac, against the old
          if (FMinReduction > 0)
            and (((AAAC - LOrderBuyTot) / AAAC) < FMinReduction) then
          begin
            LogInfo('DoFeed::BuyMode::a minimum reduction is set, and the current bid would not lower AAC enough, exiting');
            Exit(True);
          end;
        end;

        //update order depending on type
        if FUseMarketBuy then
          LGDAXOrder.OrderType:=otMarket
        else
        begin
          LGDAXOrder.OrderType:=otLimit;
          LGDAXOrder.Price:=LTicker.Ticker.Bid;
        end;

        //set the order up for buying
        LGDAXOrder.Side:=osBuy;
        LGDAXOrder.Size:=LOrderSize;
      end;

      LogInfo(Format('DoFeed::[buyorder]:%s [limit]:%s [price]:%f [size]:%f',[BoolToStr(LGDAXOrder.Side=osBuy,True),BoolToStr(LGDAXOrder.OrderType=otLimit,True),LGDAXOrder.Price,LGDAXOrder.Size]));

      //call the manager to place the order
      LDetails:=TGDAXOrderDetailsImpl.Create(LGDAXOrder);
      if not AManager.Place(
        LDetails,
        LID,
        Error
      ) then
        Exit;

      //add limit order id's to a list so we can periodically check them
      //if we are switching positions
      if LGDAXOrder.OrderType=otLimit then
        FIDS.Add(LID);

      //if we were successful calling the order manager, report success
      PositionSuccess;
      Result:=True;
    end
    else
      Exit(True);
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TTierStrategyGDAXImpl.GetPosition(const AInventory: Extended; out
  Size: TPositionSize; out Percentage: Single; out Sell: Boolean): Boolean;
begin
  Result:=False;
  Sell:=False;
  //prioritize an all sell above everything
  if FSellItAllNow and (AInventory > 0) then
  begin
    Sell:=True;
    Percentage:=FGTFOPerc;
    Size:=psGTFO;
    Exit(True);
  end
  else
  begin
    //can't sell without inventory, this check ensures buy signals don't get ignored
    if AInventory > 0 then
    begin
      //check for any sells weighted highest to lowest in priority
      if FLargeSell then
      begin
        Sell:=True;
        Percentage:=FLargeSellPerc;
        Size:=psLarge;
        Exit(True);
      end
      else if FMidSell then
      begin
        Sell:=True;
        Percentage:=FMidSellPerc;
        Size:=psMid;
        Exit(True);
      end
      else if FSmallSell then
      begin
        Sell:=True;
        Percentage:=FSmallSellPerc;
        Size:=psSmall;
        Exit(True);
      end;
    end;

    //check for any buys weighted highest to lowest in priority
    if not FDontBuy then
    begin
      if FLargeBuy then
      begin
        Sell:=False;
        Percentage:=FLargePerc;
        Size:=psLarge;
        Exit(True);
      end
      else if FSmallBuy then
      begin
        Sell:=False;
        Percentage:=FSmallPerc;
        Size:=psSmall;
        Exit(True);
      end;
    end;
  end;
end;

procedure TTierStrategyGDAXImpl.PositionSuccess;
begin
  //init all signal flags to false
  FDontBuy:=False;
  FLargeBuy:=False;
  FSmallBuy:=False;
  FLargeSell:=False;
  FMidSell:=False;
  FSmallSell:=False;
  FSellItAllNow:=False;
end;

procedure TTierStrategyGDAXImpl.ClearOldPositions(const AManager: IOrderManager);
var
  I:Integer;
  LDetails:IOrderDetails;
  LError:String;
begin
  //will iterate all managed positions and cancel those not completed
  for I:=0 to Pred(FIDS.Count) do
  begin
    if AManager.Exists[FIDS[I]] then
    begin
      if AManager.Status[FIDS[I]]<>omCompleted then
        if not AManager.Cancel(FIDS[I],LDetails,LError) then
        begin
          LogError('ClearOldPositions::' + LError);
          Exit;
        end;
    end;
  end;

  //if everything went well, clear the positions
  FIDS.Clear;
end;

function TTierStrategyGDAXImpl.ChoppyWaters: Boolean;
var
  I: Integer;
  LAvgAnc,
  LAvgDev,
  LChopInd: Single;
const
  CHOP_MAGIC = 0.002;
begin
  Result:=False;

  LogInfo('ChoppyWaters::starting');
  //if we don't care about choppy market, then exit
  if not FAvoidChop then
  begin
    LogInfo('ChoppyWaters::not avoiding chop, exiting');
    Exit;
  end;

  //find the average anchor price and deviation
  LAvgAnc:=0;
  LAvgDev:=0;
  for I := 0 to Pred(FChannel.Count) do
  begin
    LAvgAnc:=LAvgAnc + FChannel.ByIndex[I].AnchorPrice;
    LAvgDev:=LAvgDev + FChannel.ByIndex[I].StdDev;
  end;
  LAvgAnc:=LAvgAnc / FChannel.Count;
  LAvgDev:=LAvgDev / FChannel.Count;
  LogInfo(
    Format(
      'ChoppyWaters::[AvgAnchor]-%s [AvgDeviation]-%s',
      [FloatToStr(LAvgAnc),FloatToStr(LAvgDev)]
    )
  );

  //now that we have the averages we need to find the largest of
  //this calc, or the magic chop calc
  if UseMarketBuy then
    LChopInd:=((MarketFee * LAvgAnc) + (MinProfit * LAvgAnc)) / 2
  else
    LChopInd:=((LimitFee * LAvgAnc) + (MinProfit * LAvgAnc)) / 2;

  if (CHOP_MAGIC * LAvgAnc) > LChopInd then
  begin
    LogInfo('ChoppyWaters::magic chop greater than calc');
    LChopInd:=CHOP_MAGIC * LAvgAnc;
  end;

  LogInfo('ChoppyWaters::deviation must be greater than [ChopIndicator]-' + FloatToStr(LChopInd));
  Result:=LAvgDev < LChopInd;
end;

function TTierStrategyGDAXImpl.GetAvoidChop: Boolean;
begin
  Result:=FAvoidChop;
end;

procedure TTierStrategyGDAXImpl.SetAvoidChop(const AValue: Boolean);
begin
  FAvoidChop:=AValue;
end;

constructor TTierStrategyGDAXImpl.Create(const AOnInfo, AOnError,
  AOnWarn: TStrategyLogEvent);
begin
  inherited Create(AOnInfo,AOnError,AOnWarn);
  FChannel:=TChannelStrategyImpl.Create(AOnInfo,AOnError,AOnWarn);
  FIDS:=TFPGList<String>.Create;
  FSmallPerc:=0.02;
  FMidPerc:=0.03;
  FLargePerc:=0.05;
  FSmallSellPerc:=0.05;
  FMidSellperc:=0.10;
  FLargeSellPerc:=0.20;
  FMarketFee:=0.003;//account for slippage on market orders
  FLimitFee:=0.0015;
  FMinProfit:=0;
  FMinReduction:=0;
  FUseMarketBuy:=False;
  FUseMarketSell:=False;
  FIgnoreProfitPerc:=0;
  FGTFOPerc:=0;
  FAvoidChop:=False;
  InitChannel;
end;

destructor TTierStrategyGDAXImpl.Destroy;
begin
  FChannel:=nil;
  FIDS.Free;
  inherited Destroy;
end;

end.

