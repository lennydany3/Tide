import Image from "next/image";

type Props = {
  screen: "today" | "history" | "insights";
  alt: string;
  priority?: boolean;
  className?: string;
  sizes?: string;
  /** The readout printed under the device, in the telemetry register. */
  caption?: string;
};

/**
 * A real screen from the app, in a squared instrument frame.
 *
 * The screenshots are rendered from the Flutter app itself by
 * product/tool/site_screenshots_test.dart, so they never show a screen the app
 * does not have. Re-run that after a visible app change; never hand-edit the
 * images.
 *
 * The frame is part of the site's language rather than decoration around it:
 * square corners like everything else, a 1px compartment border, and a
 * telemetry strip above and below the glass that names the screen and its
 * aspect. A rounded bezel would have been the one soft object on a page built
 * specifically out of right angles.
 */
export function Phone({
  screen,
  alt,
  priority,
  className = "",
  sizes,
  caption,
}: Props) {
  return (
    <figure className={`flex flex-col ${className}`}>
      <div className="flex items-center justify-between border border-b-0 border-hairline bg-shelf px-3 py-2">
        <span className="telemetry text-silt">{screen.toUpperCase()}</span>
        <span aria-hidden className="beacon" />
        <span className="telemetry text-silt">1:2.16</span>
      </div>

      <div className="border border-hairline bg-shelf p-2">
        <div className="aspect-[390/844] bg-trench">
          <Image
            src={`/screens/${screen}.png`}
            alt={alt}
            width={1170}
            height={2532}
            priority={priority}
            sizes={sizes ?? "(min-width: 1024px) 320px, 70vw"}
            className="h-full w-full object-cover"
          />
        </div>
      </div>

      {caption ? (
        <figcaption className="telemetry border-x border-b border-hairline bg-shelf px-3 py-2 text-silt">
          {caption}
        </figcaption>
      ) : (
        <div aria-hidden className="h-0 border-x border-b border-hairline" />
      )}
    </figure>
  );
}
