

if ( SERVER ) then

	AddCSLuaFile( "shared.lua" )
	
end

if ( CLIENT ) then

	SWEP.PrintName			= "NPC_Bowcaster"			
	SWEP.Author				= "Syntax_Error752"
	SWEP.ViewModelFOV      	= 50
	SWEP.Slot				= 2
	SWEP.SlotPos			= 3
	SWEP.WepSelectIcon = surface.GetTextureID("HUD/killicons/BOWCASTER")
	
	killicon.Add( "npc_sw_weapon_752_bowcaster", "HUD/killicons/BOWCASTER", Color( 255, 80, 0, 255 ) )

end

SWEP.HoldType				= "ar2"
SWEP.Base					= "weapon_swsft_base"

SWEP.Category				= "Star Wars"

SWEP.Spawnable				= false
SWEP.AdminSpawnable			= false

SWEP.ViewModel				= ""
SWEP.WorldModel				= "models/weapons/w_BOWCASTER.mdl"

SWEP.Weight					= 5
SWEP.AutoSwitchTo			= false
SWEP.AutoSwitchFrom			= false

local MaxTimer				=64
local CurrentTimer			=0

SWEP.Primary.Sound			= Sound( "weapons/BOWCASTER_fire.wav" )
SWEP.Primary.Recoil			= 0.5
SWEP.Primary.Damage			= 12.5
SWEP.Primary.NumShots		= 1
SWEP.Primary.Cone			= 0 --0.0125
SWEP.Primary.ClipSize		= 12
SWEP.Primary.Delay			= 1.5
SWEP.Primary.DefaultClip	= 15
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo			= "ar2"
SWEP.Primary.Tracer 		= "effect_sw_laser_green"

SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

function SWEP:PrimaryAttack()
	if self:Clip1() <= 0 then self:NpcReload()
	return end 
	
	self.Weapon:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
	self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if ( !self:CanPrimaryAttack() ) then return end
	
	// Play shoot sound
	self.Weapon:EmitSound( self.Primary.Sound )
	
	// Shoot the bullet
	self:CSShootBullet( self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone )
	
	// Remove 1 bullet from our clip
	self:TakePrimaryAmmo( 1 )
	
	if ( self.Owner:IsNPC() ) then return end
	
	// Punch the player's view
	self.Owner:ViewPunch( Angle( math.Rand(-0.2,-0.1) * self.Primary.Recoil, math.Rand(-0.1,0.1) *self.Primary.Recoil, 0 ) )
	
	// In singleplayer this function doesn't get called on the client, so we use a networked float
	// to send the last shoot time. In multiplayer this is predicted clientside so we don't need to 
	// send the float.
	if ( (game.SinglePlayer() && SERVER) || CLIENT ) then
		self.Weapon:SetNetworkedFloat( "LastShootTime", CurTime() )
	end
	
end


function SWEP:CSShootBullet( dmg, recoil, numbul, cone )

	numbul 	= numbul 	or 1
	cone 	= cone 		or 0.01

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= self.Owner:GetShootPos()			// Source
	bullet.Dir 		= self.Owner:GetAimVector()			// Dir of bullet
	bullet.Spread 	= Vector( cone, cone, 0 )			// Aim Cone
	bullet.Tracer	= 1								// Show a tracer on every x bullets 
	bullet.TracerName 	= self.Primary.Tracer
	bullet.Force	= 5									// Amount of force to give to phys objects
	bullet.Damage	= dmg
	
	self.Owner:FireBullets( bullet )
	self.Weapon:SendWeaponAnim( ACT_VM_PRIMARYATTACK ) 		// View model animation
	self.Owner:MuzzleFlash()								// Crappy muzzle light
	self.Owner:SetAnimation( PLAYER_ATTACK1 )				// 3rd Person Animation
	
	if ( self.Owner:IsNPC() ) then return end
	
	// CUSTOM RECOIL !
	if ( (game.SinglePlayer() && SERVER) || ( !game.SinglePlayer() && CLIENT && IsFirstTimePredicted() ) ) then
	
		local eyeang = self.Owner:EyeAngles()
		eyeang.pitch = eyeang.pitch - recoil
		self.Owner:SetEyeAngles( eyeang )
	
	end

end


function SWEP:Reload()
		self.Weapon:DefaultReload( ACT_VM_RELOAD );
		self:SetIronsights( false )
end


function SWEP:Think()
end

Zoom = 0;
function SWEP:SecondaryAttack()

	if ( self.NextSecondaryAttack > CurTime() ) then return end
	
	if (Zoom == 0) then
		if (SERVER) then
			self.Owner:SetFOV( 40, 0.3 )
		end 
		
		bIronsights = !self.Weapon:GetNetworkedBool( "Ironsights", false )
		self:SetIronsights( bIronsights )
		Zoom = 1
		self.NextSecondaryAttack = CurTime() + 0.3
		return
	end
	if (Zoom == 1) then
		if (SERVER) then
			self.Owner:SetFOV( 0, 0.3 )
		end
		Zoom = 0
		self:SetIronsights( false )
		self.NextSecondaryAttack = CurTime() + 0.3
		return
	end
end


function SWEP:Holster() 
	if (SERVER) then
		self.Owner:SetFOV( 0, 0.3 )
	end
	Zoom = 0
	self:SetIronsights( false )
	return true
end
