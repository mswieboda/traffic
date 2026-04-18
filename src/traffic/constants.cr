module Traffic
  TileSize = 256.0_f32
  
  # Proportional Lane Offsets (4 lanes total)
  Lane1 = 0.125_f32 * TileSize # Outer
  Lane2 = 0.375_f32 * TileSize # Inner / Turn
  Lane3 = 0.625_f32 * TileSize # Inner / Turn
  Lane4 = 0.875_f32 * TileSize # Outer
  
  # Trigger/Detection Thresholds
  ThresholdTurn   = 0.1_f32 * TileSize
  LookAheadDist   = 0.15_f32 * TileSize
  SignalCheckDist = 0.25_f32 * TileSize
end
