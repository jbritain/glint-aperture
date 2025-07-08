import type {} from "./iris";

// a texture which can be safely read from and written to in different places
// it works by having texture A and texture B
// if you want to "flip" the texture, you call .flip() - this swaps the two textures around
// if you want to "unflip" the texture, you call .unflip() - this makes the texture read from wherever it was last written to
// it is "unflipped" by default
export default class FlippableTexture {
  public name: string;
  private _imageName: string;
  private _format: InternalTextureFormat;
  private _width: number;
  private _height: number;
  private _depth: number;
  private clearColorR: number;
  private clearColorG: number;
  private clearColorB: number;
  private clearColorA: number;
  private _clear: boolean;
  private _mipmap: boolean;
  private flipped = false;
  private unflipped = true;

  private textureA: Texture | BuiltTexture;
  private textureB: Texture | BuiltTexture;

  constructor(name: string) {
    this.name = name;
  }

  public format(internalFormat: InternalTextureFormat): FlippableTexture {
    this._format = internalFormat;

    return this;
  }

  public width(width: number): FlippableTexture {
    this._width = width;

    return this;
  }

  public height(height: number): FlippableTexture {
    this._height = height;

    return this;
  }

  public depth(depth: number): FlippableTexture {
    this._depth = depth;

    return this;
  }

  public clearColor(
    r: number,
    g: number,
    b: number,
    a: number,
  ): FlippableTexture {
    this.clearColorR = r;
    this.clearColorG = g;
    this.clearColorB = b;
    this.clearColorA = a;

    return this;
  }

  public clear(clear: boolean): FlippableTexture {
    this._clear = clear;
    return this;
  }

  public mipmap(mipmap: boolean): FlippableTexture {
    this._mipmap = mipmap;
    return this;
  }

  public imageName(imageName: string): FlippableTexture {
    this._imageName = imageName;
    return this;
  }

  public build(): FlippableTexture {
    this.textureA = new Texture(this.name + "_a");
    this.textureB = new Texture(this.name + "_b");

    if (this._format) {
      this.textureA.format(this._format);
      this.textureB.format(this._format);
    }

    if (this._width) {
      this.textureA.width(this._width);
      this.textureB.width(this._width);
    }

    if (this._height) {
      this.textureA.height(this._height);
      this.textureB.height(this._height);
    }

    if (this._depth) {
      this.textureA.depth(this._depth);
      this.textureB.depth(this._depth);
    }

    if (this._imageName) {
      this.textureA.imageName(this._imageName + "_a");
      this.textureB.imageName(this._imageName + "_b");
    }

    if (this.clearColorR) {
      this.textureA.clearColor(
        this.clearColorR,
        this.clearColorG,
        this.clearColorB,
        this.clearColorA,
      );
      this.textureB.clearColor(
        this.clearColorR,
        this.clearColorG,
        this.clearColorB,
        this.clearColorA,
      );
    }

    if (this._clear) {
      this.textureA.clear(this._clear);
      this.textureB.clear(this._clear);
    }

    if (this._mipmap) {
      this.textureA.mipmap(this._mipmap);
      this.textureB.mipmap(this._mipmap);
    }

    this.textureA = this.textureA.build();
    this.textureB = this.textureB.build();
    defineGlobally(this.name, this.sampler);
    return this;
  }

  public get sampler() {
    return this.name + (this.flipped ? "_a" : "_b");
  }

  public get target() {
    return this.flipped != this.unflipped ? this.textureB : this.textureA;
  }

  // Swaps the sampler and rendertarget buffers. If the texture is currently "unflipped", this will cause the rendertarget to move, but the sampler to remain the same, meaning whatever was last written is still accessable in the sampler.
  public flip(): void {

    if(this.unflipped) print("unflipped, disabling");
    if (!this.unflipped) this.flipped = !this.flipped;
    print("flipped: " +  this.flipped);
    this.unflipped = false;
    defineGlobally(this.name, this.sampler);
    print("sampler is now " + this.sampler);
    print(
      "target is now " +
        this.name +
        (this.flipped != this.unflipped ? "_b" : "_a"),
    );
    print("---");
  }

  // Causes the rendertarget to point to the same buffer as the sampler until the next flip operation. This is the default state.
  public unflip(): void {
    if (this.unflipped) return;
    this.flipped = !this.flipped;
    this.unflipped = true;
    defineGlobally(this.name, this.sampler);
    print("sampler is now " + this.sampler);
    print(
      "target is now " +
        this.name +
        (this.flipped != this.unflipped ? "_b" : "_a"),
    );
    print("---");
  }
}
